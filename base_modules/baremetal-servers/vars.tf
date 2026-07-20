variable "server" {
  description = "Параметры сервера"
  type = object({
    project_id = string

    location_id          = optional(string)
    location_name        = optional(string)
    configuration_id     = optional(string)
    configuration_name   = optional(string)
    os_id                = optional(string)
    os_name              = optional(string)
    os_version_name      = optional(string)

    public_subnet_cidr   = optional(string)
    private_subnet_id    = optional(string)
    private_subnet_cidr  = optional(string)
    private_subnet_ip    = optional(string)
    private_vlan_id      = optional(string)
    create_private_subnet = optional(bool, false)
    add_private_vlan     = optional(bool, false)

    ssh_key_name    = optional(string)
    ssh_key         = optional(string)
    user_data       = optional(string)
    os_host_name    = optional(string)
    os_password     = optional(string)
    price_plan_name = optional(string)

    partitions_config = optional(object({
      disk_configs = optional(list(object({
        name      = string
        disk_type = string
      })), [])

      soft_raid_configs = optional(list(object({
        name      = string
        level     = string
        disk_type = string
        count     = optional(number)
      })), [])

      disk_partitions = list(object({
        mount        = string
        size         = optional(number)
        size_percent = optional(number)
        raid         = optional(string)
        fs_type      = optional(string)
        disk_name    = optional(string)
      }))
    }), null)

    force_update_additional_params = optional(bool, false) # Флаг отвечающий за переустановку ОС на сервере

    timeouts = optional(object({
      create = optional(string, "60m")
      update = optional(string, "60m")
      delete = optional(string, "60m")
    }), {})
  })

  validation {
    condition     = try(var.server.public_subnet_cidr, null) == null || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+$", var.server.public_subnet_cidr))
    error_message = "server.public_subnet_cidr должен быть в формате CIDR."
  }

  validation {
    condition     = try(var.server.private_subnet_cidr, null) == null || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+$", var.server.private_subnet_cidr))
    error_message = "server.private_subnet_cidr должен быть в формате CIDR."
  }

  validation {
    condition = !(try(var.server.create_private_subnet, false) && try(var.server.private_vlan_id, null) == null)
    error_message = "При create_private_subnet=true необходимо указать private_vlan_id."
  }
}