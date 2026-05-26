# Región de AWS 
variable "aws_region" {
  type        = string
  description = "Región de AWS donde se crearán los recursos."
  default     = "eu-west-3" 
}

# Zona de disponibilidad 
variable "aws_zone" {
  type        = string
  description = "Zona de disponibilidad específica dentro de la región."
  default     = "eu-west-3a"
}

# Tipo de Instancia (Capa Gratuita de AWS)
variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2. Usamos t3.micro (o t2.micro) para entrar en la capa gratuita."
  default     = "t3.micro" 
}

# Buscador Automático de la AMI de Ubuntu 24.04 LTS (Forma correcta y Senior)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID oficial de Canonical (creadores de Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Tu IP Pública para proteger el acceso SSH
variable "my_ip" {
  type        = string
  description = "Tu IP pública con máscara /32 (Ejemplo: 182.25.40.12/32) para restringir el acceso SSH solo a ti."
}

# Tu Clave Pública SSH para inyectarla en la máquina
variable "public_key_content" {
  type        = string
  description = "El contenido de tu clave pública SSH (normalmente lo que hay dentro de ~/.ssh/id_rsa.pub)."
}

variable "aws_access_key" {
  type        = string
  description = "Access Key de AWS"
}

variable "aws_secret_key" {
  type        = string
  description = "Secret Key de AWS"
}