# Changelog - CYNA-GROUP-7

## [1.1.0] - 2026-06-03

### Infrastructure AWS Cloud

#### PostgreSQL RDS avec AWS Secrets Manager
- Déploiement RDS PostgreSQL 15.4 managé
- Architecture Multi-AZ (99.95% SLA)
- Backups automatiques (RPO 5 min)
- Failover automatique (<2 min)
- Coût optimisé : db.t3.micro (~$15-20/mois)

#### Sécurité
- AWS Secrets Manager intégré
- Zéro credential hardcodé
- Rotation automatique des mots de passe
- Encryption at rest & in transit
- Isolation réseau (subnets privés)

#### Architecture Multi-AZ
- Déploiement sur 2 Availability Zones (eu-west-3a, eu-west-3b)
- Redondance pour EKS et RDS

### Nouveaux Fichiers

```
terraform/
├── aws-main.tf
├── aws-variables.tf
├── aws-outputs.tf
└── README-AWS.md

QUICKSTART.md
COMMANDS.md
CHANGELOG.md
```

### Modifications

#### `terraform/`
- Suppression des fichiers Azure (main.tf, variables.tf, outputs.tf)
- Conservation uniquement des fichiers AWS (aws-*.tf)
- Lab réel sur Hyper-V (voir docs/LAB_HYPERV.md)

#### `README.md`
- Ajout badge PostgreSQL et AWS
- Nouvelle section "Architecture Hybride" (Lab Hyper-V + AWS Cloud)
- Mise à jour guide de déploiement

#### `docs/fiche_technique_lab.md`
- Ajout section AWS Cloud Target
- Mise à jour des prérequis (AWS CLI)
- Nouvelle section déploiement AWS
- Ajout changelog v1.1.0

### Coûts Estimés

| Composant | Type | Coût/mois |
|-----------|------|-----------|
| PostgreSQL RDS | db.t3.micro | $15-20 |
| EKS Cluster | Control plane | $72 |
| Secrets Manager | 1 secret | $0.40 |
| Total | | ~$87/mois |

### Points Forts
1. Services managés AWS (RDS, Secrets Manager, EKS)
2. Haute disponibilité : Architecture Multi-AZ
3. Sécurité : Zero hardcoded credentials
4. Infrastructure as Code : Terraform AWS
5. Automation, monitoring, documentation

---

## [1.0.0] - 2026-06-23

### Version Initiale

- Infrastructure Lab Hyper-V (pfSense, Active Directory, Docker Stack)
- Wazuh SIEM + SOC
- Prometheus + Grafana monitoring
- Ansible playbooks
- Docker Compose
- CI/CD GitHub Actions

---

## Support

- [QUICKSTART.md](QUICKSTART.md)
- [terraform/README-AWS.md](terraform/README-AWS.md)
- [COMMANDS.md](COMMANDS.md)
