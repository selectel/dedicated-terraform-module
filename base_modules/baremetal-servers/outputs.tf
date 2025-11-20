output "server_id" {
  description = "ID созданного сервера"
  value       = selectel_dedicated_server_v1.server.id
}

output "server_name" {
  description = "Имя сервера"
  value       = selectel_dedicated_server_v1.server.os_host_name
}