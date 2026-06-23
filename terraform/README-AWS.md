# Terraform AWS - Infrastructure Cloud

## Architecture

Infrastructure AWS avec PostgreSQL RDS et AWS Secrets Manager.

### Caractéristiques :

- Multi-AZ : Haute disponibilité sur 2 zones
- Managed Service : Backups, patches, monitoring automatiques
- Sécurité : Credentials dans Secrets Manager
- Coût : db.t3.micro (~$15-20/mois)

## Déploiement

### Initialiser
```bash
cd terraform
terraform init
```

### Valider
```bash
terraform validate
terraform plan
```

### Déployer
```bash
terraform apply -var="environment=development"
```

### Récupérer les credentials
```bash
terraform output secrets_manager_secret_name
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw secrets_manager_secret_name) \
  --query SecretString \
  --output text | jq .
```

Résultat :
```json
{
  "username": "cynaadmin",
  "password": "GénéréAleatoirement!",
  "engine": "postgres",
  "host": "cyna7-postgres-db.xxxxx.eu-west-3.rds.amazonaws.com",
  "port": 5432,
  --query SecretString --output text | jq .
```

## Architecture Réseau

```
VPC 172.16.0.0/16
├── Subnets Publics (ALB)
│   ├── 172.16.1.0/24 (eu-west-3a)
│   └── 172.16.2.0/24 (eu-west-3b)
├── Subnets Privés EKS
│   ├── 172.16.10.0/24 (eu-west-3a)
│   └── 172.16.11.0/24 (eu-west-3b)
└── Subnets Privés RDS
    ├── 172.16.20.0/24 (eu-west-3a)
    └── 172.16.21.0/24 (eu-west-3b)
```

## Coûts Estimés

| Ressource | Type | Coût/mois |
|-----------|------|-----------|
| RDS PostgreSQL | db.t3.micro | $15 |
| EKS Cluster | Control plane | $72 |
| Secrets Manager | 1 secret | $0.40 |
| Total | | ~$87/mois |

## Sécurité

Pratiques implémentées :
- Secrets Manager : Credentials sécurisés
- Encryption at rest : RDS storage chiffré
- Network isolation : DB dans subnets privés
- Security Groups : Accès PostgreSQL limité au VPC
- IAM Roles : Pas de hardcoded ARN

## Test Connexion

```bash
aws eks update-kubeconfig --name $(terraform output -raw eks_cluster_name)
kubectl run psql-client --rm -it --image=postgres:15 -- bash
```

## Cleanup

```bash
terraform destroy
```