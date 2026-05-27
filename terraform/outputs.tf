# Dirección IP Pública de la instancia (Para entrar a la Web de Open WebUI)
output "server_public_ip" {
  description = "La dirección IP pública del servidor para ver la web."
  value       = aws_instance.llm_server.public_ip
}

# NUEVO: Comando SSM seguro listo para usar en tu terminal (Reemplaza al SSH antiguo)
output "ssm_connect_command" {
  description = "Comando para acceder de forma segura al servidor mediante AWS Systems Manager sin puertos abiertos."
  value       = "aws ssm start-session --target ${aws_instance.llm_server.id}"
}

# ID de la VPC 
output "vpc_id" {
  description = "El ID de la VPC dedicada que se ha creado para este proyecto."
  value       = aws_vpc.main_vpc.id
}