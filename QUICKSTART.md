# Guide de Démarrage - CYNA-GROUP-7

## Partie 1 : AWS Cloud

### Prérequis
```bash
# Installer AWS CLI (Ubuntu)
sudo apt update
sudo apt install awscli -y

# Configurer les credentials AWS
aws configure
```

### Déploiement
```bash
cd terraform
terraform init
terraform plan
terraform apply -var="environment=development"
```

Infrastructure créée :
- VPC AWS avec 6 subnets (2 AZ)
- RDS PostgreSQL 15.4 (db.t3.micro)
- AWS Secrets Manager
- EKS Cluster
- Security Groups

### Récupérer les credentials DB

```bash
terraform output connection_command

# Ou directement
SECRET_NAME=$(terraform output -raw secrets_manager_secret_name)
aws secretsmanager get-secret-value \
  --secret-id $SECRET_NAME \
  --query SecretString \
  --output text | jq .
```

## Partie 2 : Lab Hyper-V (Wazuh + Monitoring)

### Architecture Lab

Le lab est déjà déployé sur Hyper-V avec 4 VMs :
- **VM-pfSense** (192.168.1.1) : Firewall/Routeur
- **VM-AD-CYNA** (192.168.1.10) : Active Directory (cyna.local)
- **VM-DevOps-Linux** (192.168.1.102) : Docker Stack
- **VM-SOC-Wazuh** (192.168.1.103) : SIEM

Voir [docs/LAB_HYPERV.md](docs/LAB_HYPERV.md) pour la configuration détaillée.

### Configuration via Ansible

Depuis votre machine de contrôle (ou directement sur VM-DevOps) :

```bash
cd ansible
ansible-playbook playbooks/deploy-agent-wazuh.yml -K
ansible-playbook playbooks/deploy-apps-monitoring.yml -K
# -K = demande votre mot de passe sudo
```

### Accès aux services

- Wazuh Dashboard : `https://192.168.1.103`
- Grafana : `http://192.168.1.102:3000`
- Prometheus : `http://192.168.1.102:9090`
- DVWA : `http://192.168.1.102:8080`
- pfSense WebGUI : `https://192.168.1.1`

## Partie 3 : Ansible

### Installation
```bash
sudo apt update
sudo apt install ansible -y
### Déployer Wazuh
```bash
cd ansible
ansible-playbook playbooks/deploy-agent-wazuh.yml -K
# -K = demande votre mot de passe sudo
```

### Déployer Monitoring
```bash
ansible-playbook playbooks/deploy-apps-monitoring.yml -K
```

```

### Déployer Monitoring
```bash
ansible-playbook playbooks/deploy-apps-monitoring.yml -K
```

## Test Connexion PostgreSQL

### Installation psql
```bash
sudo apt install postgresql-client -y
```ord /tmp/db-creds.json)
export PGDATABASE=$(jq -r .dbname /tmp/db-creds.json)
```

3. **Se connecter**
```bash
psql -h $PGHOST -U $PGUSER -d $PGDATABASE

# Si succès :
comptabilite=> SELECT version();
```

### Connexion
```bash
SECRET_NAME="cyna7-db-credentials"
aws secretsmanager get-secret-value --secret-id $SECRET_NAME \
  --query SecretString --output text > /tmp/db-creds.json

export PGHOST=$(jq -r .host /tmp/db-creds.json)
export PGUSER=$(jq -r .username /tmp/db-creds.json)
export PGPASSWORD=$(jq -r .password /tmp/db-creds.json)
export PGDATABASE=$(jq -r .dbname /tmp/db-creds.json)

psql -h $PGHOST -U $PGUSER -d $PGDATABASE
```

## Cleanup

```bash
cd terraform
terraform destroy
```

## Troubleshooting

**RDS prend du temps à créer**
- Normal: 5-15 minutes

**AccessDenied Secrets Manager**
- Vérifier les permissions IAM

**Terraform state locked**
```bash
terraform force-unlock <LOCK_ID>
```