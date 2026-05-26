#!/bin/bash
# Redirigir la salida de error y log para poder depurar si algo falla
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== 1. Actualizando el sistema ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo "=== 2. Creando la memoria Swap (3 GB) para FinOps ==="
# t3.micro solo tiene 1GB de RAM. Creamos 3GB de SWAP para simular 4GB en total.
SWAPFILE="/swapfile"
if [ ! -f "$SWAPFILE" ]; then
    fallocate -l 3G $SWAPFILE
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon $SWAPFILE
    # Hacerlo permanente entre reinicios
    echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
    echo "Swap de 3GB configurado exitosamente."
else
    echo "El archivo Swap ya existe."
fi

echo "=== 3. Instalando Docker y dependencias ==="
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

# Añadir la clave oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Añadir el repositorio de Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.p/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Instalar Docker Compose v2 (plugin oficial)
apt-get install -y docker-compose-plugin

# Habilitar e iniciar el servicio de Docker
systemctl enable docker
systemctl start docker

echo "=== 4. Preparando la estructura de directorios del proyecto ==="
# Creamos la carpeta donde residirá la configuración del stack
mkdir -p /app/config
cd /app

touch /app/config/docker-compose.yml
touch /app/config/nginx.conf

echo "=== Configuración de User Data completada con éxito ==="