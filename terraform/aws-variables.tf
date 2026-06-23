# ============================================
# Variables pour AWS Infrastructure
# ============================================

variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "environment" {
  description = "Environnement (development/staging/production)"
  type        = string
  default     = "development"
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "prefix" {
  description = "Préfixe pour nommer les ressources"
  type        = string
  default     = "cyna7"
}

variable "db_name" {
  description = "Nom de la base de données PostgreSQL"
  type        = string
  default     = "comptabilite"
}

variable "db_username" {
  description = "Nom d'utilisateur admin pour PostgreSQL"
  type        = string
  default     = "cynaadmin"
  sensitive   = true
}
