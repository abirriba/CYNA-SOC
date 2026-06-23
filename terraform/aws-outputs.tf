# ============================================
# Outputs pour AWS Infrastructure
# ============================================

output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.cyna_vpc.id
}

output "rds_endpoint" {
  description = "Endpoint de la base PostgreSQL RDS"
  value       = aws_db_instance.postgres_db.endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.postgres_db.db_name
}

output "secrets_manager_secret_name" {
  description = "Nom du secret dans AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "secrets_manager_secret_arn" {
  description = "ARN du secret dans AWS Secrets Manager"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "eks_cluster_name" {
  description = "Nom du cluster EKS"
  value       = aws_eks_cluster.eks_saas.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint du cluster EKS"
  value       = aws_eks_cluster.eks_saas.endpoint
}

output "connection_command" {
  description = "Commande pour récupérer les credentials DB depuis Secrets Manager"
  value       = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_credentials.name} --query SecretString --output text | jq ."
}

output "deployment_summary" {
  description = "Résumé du déploiement"
  value = {
    region             = var.aws_region
    environment        = var.environment
    eks_cluster        = aws_eks_cluster.eks_saas.name
    database_engine    = "PostgreSQL 15.4"
    database_size      = "db.t3.micro"
    multi_az_enabled   = aws_db_instance.postgres_db.multi_az
    secrets_in_vault   = "✅ Credentials stockés dans Secrets Manager"
  }
}
