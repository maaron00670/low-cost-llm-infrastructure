# Dirección IP Pública de la instancia
output "server_public_ip" {
  description = "La dirección IP pública del servidor para ver la web."
  value       = aws_instance.llm_server.public_ip
}

# Comando SSH listo para usar
output "ssh_command" {
  description = "Comando de terminal listo para copiar y pegar para acceder al servidor por SSH."
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.llm_server.public_ip}"
}

# ID de la VPC
output "vpc_id" {
  description = "El ID de la VPC dedicada que se ha creado para este proyecto."
  value       = aws_vpc.main_vpc.id
}