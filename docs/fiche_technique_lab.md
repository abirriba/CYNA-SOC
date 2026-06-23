# Fiche Technique - Lab CYNA-GROUP-7

## Informations Générales

- Nom du projet: CYNA-GROUP-7
- Date: 2026-06-23
- Environnement: Lab (Development)
- Lab On-Premises: Hyper-V (Windows Local)
- Cloud Provider: AWS (Cloud Target)
- Région AWS: eu-west-3 (Paris)

## Objectif

Infrastructure hybride de sécurité et de monitoring :
- Lab Hyper-V : pfSense, Active Directory, Wazuh SIEM, Docker Stack (Prometheus, Grafana)
- Cloud AWS : EKS, RDS PostgreSQL, AWS Secrets Manager
- Déploiement automatisé via Ansible (lab) et Terraform (cloud)

## Architecture

### Composants Principaux (Lab Hyper-V)

1. **VM-pfSense** (192.168.1.1)
   - Firewall/Routeur FreeBSD
   - WAN: 10.0.0.16/8 (DHCP école)
   - LAN: 192.168.1.1/24
   - Services: DHCP, NAT, Firewall

2. **VM-AD-CYNA** (192.168.1.10)
   - Windows Server 2022 Standard
   - Active Directory: cyna.local
   - DNS Server principal du lab
   - Hostname: SRV-AD-CYNA

3. **VM-DevOps-Linux** (192.168.1.102)
   - Ubuntu Server 24.04 LTS
   - Hostname: devops-cyna
   - Docker Stack: Nginx (cyna-saas), DVWA, Prometheus, Grafana
   - Wazuh Agent installé

4. **VM-SOC-Wazuh** (192.168.1.103)
   - Ubuntu Server 24.04 LTS
   - Hostname: soc-cyna
   - Wazuh Manager + Indexer + Dashboard
   - Port 1514 (agents), Port 443 (dashboard)

### Réseau

```
Hyper-V LAN-CYNA: 192.168.1.0/24
├── pfSense Gateway: 192.168.1.1
├── Active Directory: 192.168.1.10
├── DevOps Server: 192.168.1.102
└── Wazuh SIEM: 192.168.1.103
```

## Déploiement

### Prérequis

- Hyper-V sur Windows (pour lab local)
- Terraform >= 1.5.0 (pour AWS Cloud)
- Ansible >= 2.10
- AWS CLI configuré (pour le Cloud Target)
- Accès SSH aux VMs Hyper-V

### Étapes de Déploiement

#### 1. Lab Hyper-V (Configuration manuelle/Ansible)

Le lab est déjà déployé sur Hyper-V. Configuration Ansible pour les agents :

```bash
cd ansible
ansible-playbook playbooks/deploy-agent-wazuh.yml
ansible-playbook playbooks/deploy-apps-monitoring.yml
```

#### 2. Infrastructure AWS Cloud (Terraform)

```bash
# Depuis le même dossier terraform/
terraform init
terraform plan -target="aws_*"
terraform apply -target="aws_*"
```

#### 3. Configuration Wazuh (Ansible)

```bash
cd ansible
ansible-playbook playbooks/deploy-agent-wazuh.yml
```

#### 4. Monitoring Stack (Ansible)

```bash
ansible-playbook playbooks/deploy-apps-monitoring.yml
```

#### 5. Stack Docker Local

```bash
cd docker
docker compose up -d
```

## Monitoring et Supervision

### Accès aux Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://10.0.1.21:3000 | admin:admin |
| Prometheus | http://10.0.1.20:9090 | - |
| Wazuh API | https://10.0.1.10:55000 | - |

### Métriques Collectées

- **Node Exporter**: CPU, RAM, Disk, Network
- **Wazuh**: Alertes de sécurité, agents status
- **Docker**: Containers metrics

## Sécurité

### Network Security Group Rules

| Port | Protocol | Source | Destination | Description |
|------|----------|--------|-------------|-------------|
| 22 | TCP | * | * | SSH |
| 9090 | TCP | * | * | Prometheus |
| 3000 | TCP | * | * | Grafana |
| 55000 | TCP | * | * | Wazuh API |
| 1514 | TCP | Agents | Wazuh | Wazuh Agents |

### Bonnes Pratiques

- Changer les mots de passe par défaut
- Restreindre les IPs sources pour SSH
- Configurer les certificats SSL/TLS
- Activer les logs d'audit
- Configurer les alertes Wazuh

## Maintenance

### Commandes Utiles

```bash
# Vérifier le status des agents Wazuh
/var/ossec/bin/agent_control -l

# Redémarrer Wazuh manager
systemctl restart wazuh-manager

# Vérifier les targets Prometheus
curl http://localhost:9090/api/v1/targets

# Logs Docker
docker compose logs -f

# Test Ansible connectivity
ansible all -m ping
```

### Backup

- **Wazuh**: `/var/ossec/` 
- **Prometheus Data**: volume `prometheus-data`
- **Grafana Data**: volume `grafana-data`

## Changelog
### Version 1.1.0 (2026-06-23)
- Infrastructure AWS Cloud (EKS, RDS PostgreSQL)
- AWS Secrets Manager pour gestion des credentials
- Architecture Multi-AZ (haute disponibilité)
- Documentation complète (Quick Start, Commands)
### Version 1.0.0 (2026-06-23)
- Création initiale de l'infrastructure
- Déploiement Terraform
- Playbooks Ansible
- Stack Docker monitoring

## Troubleshooting

### Problème: Agent Wazuh ne se connecte pas

```bash
# Sur l'agent
tail -f /var/ossec/logs/ossec.log
systemctl restart wazuh-agent

# Sur le manager
/var/ossec/bin/agent_control -i <agent-id>
```

### Problème: Prometheus ne scrape pas

```bash
# Vérifier la configuration
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Recharger la config
curl -X POST http://localhost:9090/-/reload
```

## Documentation

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Équipe

CYNA-GROUP-7
