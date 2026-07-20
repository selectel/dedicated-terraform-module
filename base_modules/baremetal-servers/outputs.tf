output "server_id" {
  description = "ID сервера в API Selectel"
  value       = selectel_dedicated_server_v1.server.id
}

output "server_name" {
  description = "Имя сервера (os_host_name)"
  value       = selectel_dedicated_server_v1.server.os_host_name
}

output "public_ip" {
  description = "Публичный IP-адрес сервера"
  value       = selectel_dedicated_server_v1.server.public_ip
}

output "private_ip" {
  description = "Приватный IP-адрес сервера"
  value       = selectel_dedicated_server_v1.server.private_ip
}

output "private_vlan" {
  description = "VLAN ID приватной сети"
  value       = selectel_dedicated_server_v1.server.private_vlan
}

output "os_password" {
  description = "Пароль ОС"
  value       = selectel_dedicated_server_v1.server.os_password
  sensitive   = true
}

output "debug_config_check" {
  description = "Информация о найденной конфигурации"
  value = {
    config_name   = var.server.configuration_name
    location_name = var.server.location_name
    config_exists = local.config_available
    configurations_all = try(data.selectel_dedicated_configuration_v1.by_name[0].configurations, [])
  }
  sensitive = false
}
