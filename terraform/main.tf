
# Creación de la VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "llm-vpc"
  }
}

# Subred Pública donde vivirá la EC2
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.aws_zone
  map_public_ip_on_launch = true # Asigna IP pública automáticamente

  tags = {
    Name = "llm-public-subnet"
  }
}

# Internet Gateway para permitir salida/entrada a Internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "llm-vpc-igw"
  }
}

# Tabla de Enrutamiento Pública
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "llm-public-rt"
  }
}

# Asocación de la tabla de enrutamiento con la subred
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Grupo de Seguridad (Firewall)
resource "aws_security_group" "ec2_sg" {
  name        = "llm-security-group"
  description = "Reglas de acceso para el proxy de seguridad y SSH"
  vpc_id      = aws_vpc.main_vpc.id

  # Permitir tráfico web (Nginx) desde cualquier lugar
  ingress {
    description = "Acceso HTTP al Proxy Inverso"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Seguridad SSH 
  ingress {
    description = "Acceso SSH Seguro"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Filtrado por tu IP pública para evitar ataques por fuerza bruta
  }

  # Permitir que la máquina descargue paquetes, Docker images, modelos, etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "llm-instance-sg"
  }
}

# Generador automático de llaves 
resource "tls_private_key" "auto_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Clave SSH para acceder a la máquina
resource "aws_key_pair" "deployer_key" {
  key_name   = "llm-deployer-key"
  public_key = tls_private_key.auto_key.public_key_openssh  
}

# Guarda la llave privada automáticamente en tu carpeta local
resource "local_file" "ssh_key" {
  content  = tls_private_key.auto_key.private_key_pem
  filename = "${path.module}/llm-key.pem"
}


# La Instancia EC2 con el Script de Inicialización (User Data)
resource "aws_instance" "llm_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type # t2.micro es gratuita por un año
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  # Almacenamiento: Le damos 30 GB (el máximo de la capa gratuita) para que quepa el SO, Docker y el Swap
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # El script mágico que configurará el SWAP, instalará Docker y levantará todo
  user_data = file("${path.module}/templates/user_data.sh")

  tags = {
    Name = "llm-devops-infrastructure"
  }
}