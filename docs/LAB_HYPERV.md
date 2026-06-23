# Configuration Interne Détaillée des Machines du Lab Hyper-V

## Vue d'Ensemble

Lab local sur Hyper-V (Windows) simulant un environnement de production avec :
- 1 Routeur/Firewall (pfSense)
- 1 Contrôleur de domaine (Active Directory)
- 1 Serveur d'applications (Docker Stack)
- 1 Serveur SIEM (Wazuh)

**Réseau Lab** : 192.168.1.0/24 (LAN-CYNA)  
**Passerelle** : 192.168.1.1 (pfSense)  
**DNS** : 192.168.1.10 (Active Directory)

---

## 1. Machine Virtuelle : VM-pfSense (Le Pare-feu / Routeur)

### Spécifications Système (Hyper-V)

- **Système d'exploitation** : FreeBSD (pfSense Community Edition version 2.7.2, architecture 64-bit)
- **Génération de VM** : Génération 2 (Démarrage sécurisé désactivé pour compatibilité BSD)
- **Mémoire vive** : 1024 Mo (1 Go) de RAM fixe (sans mémoire dynamique)
- **Processeur virtuel** : 1 vCPU
- **Disque dur virtuel** : 10 Go SSD (format VHDX)
- **Cartes réseau virtuelles** :
  - Carte 1 : Connectée au commutateur virtuel `WAN-Internet`
  - Carte 2 : Connectée au commutateur virtuel `LAN-CYNA`

### Configuration Réseau & Interfaces

- **Interface WAN (hn0)** : Configuration IP en client DHCP. Elle obtient automatiquement l'adresse IP `10.0.0.16` avec un masque de sous-réseau `/8` de la part du réseau hôte de l'école. Passerelle par défaut : `10.0.0.1`.
- **Interface LAN (hn1)** : Configuration IP statique. Adresse IP : `192.168.1.1` avec un masque de sous-réseau `/24` (255.255.255.0). Pas de passerelle (pfSense étant lui-même la passerelle).

### Services configurés à l'intérieur de pfSense

- **Serveur DHCP (LAN)** : Activé sur l'interface LAN. Plage d'adresses distribuées (IP Pool) : de `192.168.1.100` à `192.168.1.150`.
- **DNS distribué par DHCP** : Le serveur DHCP est configuré pour distribuer l'adresse IP de notre Active Directory (`192.168.1.10`) comme serveur DNS principal pour toutes les machines du LAN.
- **Règles de Pare-feu (Firewall Rules)** :
  - Règle WAN : Blocage par défaut de tout trafic entrant non sollicité (Default Deny).
  - Règle LAN : Autorisation de tout trafic sortant vers le WAN pour permettre l'accès Internet aux VMs (LAN to Any).
- **NAT (Network Address Translation)** : Traduction d'adresses réseau activée en mode automatique pour masquer les IPs privées du LAN derrière l'IP publique du WAN.

### Identifiants de sécurité

- **Console système (SSH / Hyper-V)** : Utilisateur `admin` / Mot de passe par défaut `pfsense`.
- **Interface d'administration Web (WebGUI)** : Accessible en HTTPS à l'adresse `https://192.168.1.1` depuis la machine Windows. Utilisateur `admin` / Mot de passe personnalisé lors de l'assistant de démarrage.

---

## 2. Machine Virtuelle : VM-AD-CYNA (Le Contrôleur de Domaine)

### Spécifications Système (Hyper-V)

- **Système d'exploitation** : Windows Server 2022 Standard (avec l'environnement graphique Expérience de bureau)
- **Nom NetBIOS du serveur** : `SRV-AD-CYNA`
- **Génération de VM** : Génération 2 (Démarrage sécurisé activé)
- **Mémoire vive** : 2048 Mo (2 Go) de RAM fixe
- **Processeur virtuel** : 1 vCPU
- **Disque dur virtuel** : 40 Go SSD (format VHDX)
- **Carte réseau virtuelle** : Connectée uniquement au commutateur virtuel `LAN-CYNA`

### Configuration Réseau Statique

- **Adresse IP** : `192.168.1.10`
- **Masque de sous-réseau** : `255.255.255.0`
- **Passerelle par défaut** : `192.168.1.1` (Le pare-feu pfSense)
- **Serveur DNS principal** : `127.0.0.1` (Le serveur est son propre résolveur DNS)
- **Serveur DNS auxiliaire** : `8.8.8.8` (DNS public de Google pour assurer la résolution externe)

### Services configurés à l'intérieur de Windows Server

- **Rôle Active Directory (AD DS)** : Installé et promu. Création d'une nouvelle forêt et d'un domaine racine nommé `cyna.local`. Niveau fonctionnel de la forêt et du domaine : Windows Server 2016.
- **Serveur DNS Windows** : Zone de recherche directe créée pour `cyna.local`. Zone de recherche inversée configurée pour le sous-réseau `1.168.192.in-addr.arpa`.
- **Organisation des comptes (OUs de test)** :
  - Unité d'organisation principale : `CYNA_Users`
  - Sous-unité : `Administrateurs` (contenant le compte de test administrateur)
  - Sous-unité : `Employes` (contenant des comptes d'utilisateurs factices pour la simulation)

### Identifiants de sécurité

- **Compte administrateur du domaine** : Utilisateur `CYNA\Administrateur` / Mot de passe créé à l'installation.

---

## 3. Machine Virtuelle : VM-DevOps-Linux (Le Serveur d'Applications)

### Spécifications Système (Hyper-V)

- **Système d'exploitation** : Ubuntu Server 24.04 LTS (architecture 64-bit)
- **Nom d'hôte (Hostname)** : `devops-cyna`
- **Génération de VM** : Génération 2 (Démarrage sécurisé désactivé pour compatibilité noyau Linux)
- **Mémoire vive** : 1024 Mo (1 Go) de RAM fixe
- **Processeur virtuel** : 1 vCPU
- **Disque dur virtuel** : 20 Go SSD (format VHDX)
- **Carte réseau virtuelle** : Connectée uniquement au commutateur virtuel `LAN-CYNA`

### Configuration Réseau (DHCP)

- **Adresse IP obtenue** : `192.168.1.102` (distribuée par pfSense, configurée de manière statique via bail statique DHCP).
- **Serveur DNS configuré** : `192.168.1.10` (Notre Active Directory, ce qui lui permet de résoudre le domaine `cyna.local`).

### Services & Outils DevOps configurés

- **Serveur SSH (OpenSSH)** : Activé et configuré sur le port par défaut 22 pour permettre l'administration à distance.
- **Moteur Docker (version 29.1.3)** : Installé et configuré pour démarrer automatiquement avec le système (`systemctl enable --now docker`). L'utilisateur par défaut appartient au groupe système `docker` pour s'exécuter sans élévation de privilèges.
- **Ansible (version 2.16.3)** : Installé via le gestionnaire de paquets de base. Le fichier de configuration `/etc/ansible/ansible.cfg` a été optimisé (désactivation de la vérification de clé SSH hôte pour les tests automatisés).
- **Conteneurs Docker déployés et actifs** :
  - Conteneur **`cyna-saas`** (Image Nginx) : Serveur web simulant la plateforme SaaS de CYNA. Redirection du port hôte 80 vers le port 80 du conteneur.
  - Conteneur **`dvwa`** (Image `vulnerables/web-dvwa` de l'OWASP) : Serveur de test de failles de sécurité. Redirection du port hôte 8080 vers le port 80 du conteneur pour éviter les conflits de ports.
  - Conteneur **`prometheus`** : Outil de monitoring, mappé sur le port 9090.
  - Conteneur **`grafana`** : Interface graphique de supervision, mappée sur le port 3000.
- **Agent Wazuh (wazuh-agent)** : Installé automatiquement via notre playbook Ansible. Configuré pour remonter ses alertes de sécurité en temps réel vers le serveur SIEM à l'adresse `192.168.1.103`.

### Identifiants de sécurité

- **Session système / Connexion SSH** : Utilisateur `cynaadmin` / Mot de passe défini à l'installation.
- **Interface d'administration DVWA** : Accessible à l'adresse `http://192.168.1.102:8080`. Utilisateur `admin` / Mot de passe `password`.
- **Interface Grafana** : Accessible à l'adresse `http://192.168.1.102:3000`. Utilisateur `admin` / Mot de passe `admin` par défaut.

---

## 4. Machine Virtuelle : VM-SOC-Wazuh (Le SIEM / SOC)

### Spécifications Système (Hyper-V)

- **Système d'exploitation** : Ubuntu Server 24.04 LTS (architecture 64-bit)
- **Nom d'hôte (Hostname)** : `soc-cyna`
- **Génération de VM** : Génération 2 (Démarrage sécurisé désactivé)
- **Mémoire vive** : 5120 Mo (5 Go) de RAM fixe (nécessaire pour le bon fonctionnement de la base de données Java/Elasticsearch de l'indexeur)
- **Processeurs virtuels** : 2 vCPUs (exigence minimale pour l'indexation des logs de Wazuh)
- **Disque dur virtuel** : 30 Go SSD (format VHDX)
- **Carte réseau virtuelle** : Connectée uniquement au commutateur virtuel `LAN-CYNA`

### Configuration Réseau (DHCP)

- **Adresse IP obtenue** : `192.168.1.103` (distribuée automatiquement par pfSense).
- **Résolution DNS** : Dirigée vers notre contrôleur de domaine `192.168.1.10` pour l'intégration de la sécurité avec l'Active Directory.

### Services de sécurité configurés à l'intérieur de Wazuh

- **Générateur d'entropie `haveged`** : Installé et activé pour pallier le manque d'entropie matérielle virtuelle et accélérer la génération de clés SSL lors de l'installation.
- **Surcharges système (Overrides Systemd)** : Fichiers d'override créés pour les services `wazuh-indexer` et `wazuh-manager` afin d'augmenter le délai de démarrage initial à vingt minutes (1200 secondes), évitant ainsi les échecs de démarrage (timeouts) dus à la lenteur des disques physiques du LAB.
- **Wazuh Indexer (Base de données)** : Configuré, actif et sécurisé par des certificats internes.
- **Wazuh Manager (Le cerveau de sécurité)** : Actif, configuré pour écouter sur les ports de communication cryptés de l'agent (port 1514) et d'enregistrement (port 1515).
- **Wazuh Dashboard (Interface d'administration)** : Actif, configuré pour exposer l'interface d'administration Web de manière sécurisée en HTTPS sur le port par défaut 443.

### Identifiants de sécurité

- **Session système / Connexion SSH** : Utilisateur `cynaadmin` / Mot de passe défini à l'installation.
- **Tableau de bord de sécurité (Dashboard)** : Accessible en HTTPS à l'adresse `https://192.168.1.103` depuis la machine Windows. Utilisateur `admin` / Mot de passe généré lors de la fin de l'installation : `j.InkeW0KXnvb*YNDs?Ks1.+2tO7cm5J`.

---

## Tableau Récapitulatif

| VM                  | Hostname       | IP            | OS                    | RAM | vCPU | Services Principaux                          |
| ------------------- | -------------- | ------------- | --------------------- | --- | ---- | -------------------------------------------- |
| VM-pfSense          | pfSense        | 192.168.1.1   | FreeBSD pfSense 2.7.2 | 1Go | 1    | Firewall, DHCP, NAT                          |
| VM-AD-CYNA          | SRV-AD-CYNA    | 192.168.1.10  | Windows Server 2022   | 2Go | 1    | Active Directory, DNS (cyna.local)           |
| VM-DevOps-Linux     | devops-cyna    | 192.168.1.102 | Ubuntu Server 24.04   | 1Go | 1    | Docker (Nginx, DVWA, Prometheus, Grafana)    |
| VM-SOC-Wazuh        | soc-cyna       | 192.168.1.103 | Ubuntu Server 24.04   | 5Go | 2    | Wazuh Manager, Indexer, Dashboard (SIEM)     |

---

## Schéma Réseau

```
                          Internet (10.0.0.0/8)
                                 |
                         +-------+-------+
                         |  VM-pfSense   |
                         |  192.168.1.1  |
                         | WAN: 10.0.0.16|
                         +-------+-------+
                                 |
                 ================+================ (LAN-CYNA: 192.168.1.0/24)
                 |               |               |
         +-------+-----+  +------+------+  +-----+--------+
         | VM-AD-CYNA  |  | VM-DevOps   |  | VM-Wazuh    |
         | .10         |  | .102        |  | .103        |
         | AD + DNS    |  | Docker      |  | SIEM        |
         +-------------+  +-------------+  +-------------+
```

---

## Notes Importantes

1. **Domaine Active Directory** : `cyna.local`
2. **Plage DHCP** : 192.168.1.100 - 192.168.1.150
3. **DNS Principal** : 192.168.1.10 (Active Directory)
4. **Passerelle par défaut** : 192.168.1.1 (pfSense)
5. **Accès Externe** : Via pfSense NAT (WAN 10.0.0.16 → LAN 192.168.1.x)
6. **Sécurité** : Wazuh agents sur VM-DevOps, monitoring centralisé sur VM-SOC-Wazuh
