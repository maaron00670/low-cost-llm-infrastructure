#!/bin/bash
# Redirigir la salida de error y log para auditorías y depuración masiva
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== 1. Actualizando el sistema ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

echo "=== 2. Creando la memoria Swap (3 GB) para FinOps ==="
SWAPFILE="/swapfile"
if [ ! -f "$SWAPFILE" ]; then
    fallocate -l 3G $SWAPFILE
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon $SWAPFILE
    echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
    echo "Swap de 3GB configurado exitosamente."
else
    echo "El archivo Swap ya existe."
fi

echo "=== 3. Instalando dependencias previas ==="
apt-get install -y ca-certificates curl gnupg lsb-release git

echo "=== 4. Configurando repositorios oficiales de Docker ==="
# Crear directorio seguro para las llaves siguiendo el estándar actual de Ubuntu
mkdir -m 0755 -p /etc/apt/keyrings

# Descargar la clave criptográfica oficial de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

# Añadir el repositorio oficial corregido en sources.list.d/
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== 5. Instalando Docker Engine y Docker Compose ==="
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Asegurar el arranque del demonio de Docker
systemctl enable docker
systemctl start docker

echo "=== 6. Preparando la estructura de directorios del proyecto ==="
mkdir -p /opt/llm-infrastructure
cd /opt/llm-infrastructure

 

echo "=== Configuración de User Data completada con éxito ==="
echo "=== Creando el archivo Docker Compose de la IA ==="
cat << 'EOF' > /opt/llm-infrastructure/docker-compose.yml
version: '3.8'
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - ollama_data:/root/.ollama
    restart: always

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    depends_on:
      - ollama
    ports:
      - "80:8080"
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    volumes:
      - open_webui_data:/app/backend/data
    restart: always

volumes:
  ollama_data:
  open_webui_data:
EOF

echo "=== Levantando el stack de IA sin intervención ==="
docker compose up -d

echo "=== Esperando 15 segundos a que el motor de Ollama inicie ==="
sleep 15

# echo "=== Descargando el modelo rápido Qwen2.5 (0.5B) ==="
# docker exec -i ollama ollama run qwen2.5:0.5b ""

# echo "=== Descargando el modelo pesado Gemma (2B) ==="
# docker exec -i ollama ollama run gemma:2b ""

echo "=== Configuración de User Data completada con éxito ==="