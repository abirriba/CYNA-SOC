# ============================================
# PARTIE AWS - Infrastructure Cloud Target
# ============================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Réseau - VPC Principal CYNA
resource "aws_vpc" "cyna_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "VPC-CYNA"
    Environment = var.environment
    Project     = "CYNA-GROUP-7"
  }
}

# 2. Sous-réseaux Multi-AZ (2 zones pour un lab étudiant)
# Subnets publics pour ALB
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.cyna_vpc.id
  cidr_block              = "172.16.${count.index + 1}.0/24"
  availability_zone       = element(["eu-west-3a", "eu-west-3b"], count.index)
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Subnet-Public-${count.index + 1}"
  }
}

# Subnets privés pour EKS
resource "aws_subnet" "private_subnet_eks" {
  count             = 2
  vpc_id            = aws_vpc.cyna_vpc.id
  cidr_block        = "172.16.${count.index + 10}.0/24"
  availability_zone = element(["eu-west-3a", "eu-west-3b"], count.index)
  
  tags = {
    Name = "Subnet-Private-EKS-${count.index + 1}"
  }
}

# Subnets privés pour RDS
resource "aws_subnet" "private_subnet_db" {
  count             = 2
  vpc_id            = aws_vpc.cyna_vpc.id
  cidr_block        = "172.16.${count.index + 20}.0/24"
  availability_zone = element(["eu-west-3a", "eu-west-3b"], count.index)
  
  tags = {
    Name = "Subnet-Private-DB-${count.index + 1}"
  }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.cyna_vpc.id

  tags = {
    Name = "CYNA-IGW"
  }
}

# 4. Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cyna_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# 5. Security Group pour RDS PostgreSQL
resource "aws_security_group" "rds_sg" {
  name        = "${var.prefix}-rds-sg"
  description = "Security group pour RDS PostgreSQL"
  vpc_id      = aws_vpc.cyna_vpc.id

  ingress {
    description = "PostgreSQL depuis EKS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-rds-sg"
  }
}

# 6. DB Subnet Group pour RDS Multi-AZ
resource "aws_db_subnet_group" "main" {
  name       = "${var.prefix}-db-subnet-group"
  subnet_ids = aws_subnet.private_subnet_db[*].id

  tags = {
    Name = "${var.prefix}-db-subnet-group"
  }
}

# 7. Secrets Manager - Password généré aléatoirement
resource "random_password" "db_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.prefix}-db-credentials"
  description = "Credentials pour la base PostgreSQL (Comptabilité)"
  
  tags = {
    Name = "${var.prefix}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.postgres_db.address
    port     = 5432
    dbname   = var.db_name
  })
}

# 8. RDS PostgreSQL - Base de données managée
resource "aws_db_instance" "postgres_db" {
  identifier     = "${var.prefix}-postgres-db"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"  # Free tier éligible
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  
  # Multi-AZ seulement pour production (coût réduit pour lab)
  multi_az               = var.environment == "production" ? true : false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  skip_final_snapshot       = true  # Pour un lab - en prod mettre false
  deletion_protection       = false  # Pour faciliter cleanup du lab
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  tags = {
    Name = "SRV-DB-POSTGRES-COMPTA"
  }
}

# 9. IAM Role pour EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# 10. Cluster EKS managé pour héberger la plateforme SaaS
resource "aws_eks_cluster" "eks_saas" {
  name     = "${var.prefix}-EKS-SAAS"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = aws_subnet.private_subnet_eks[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit"]

  tags = {
    Name = "${var.prefix}-EKS-SAAS"
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}
