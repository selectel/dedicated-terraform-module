variable "server" {
  description = "Параметры сервера"
  type = object({
    project_id = string

    os_host_name = optional(string)

    location_id   = optional(string)
    location_name = optional(string)

    configuration_id   = optional(string)
    configuration_name = optional(string)

    os_id   = optional(string)
    os_name = optional(string)

    os_version_name = optional(string)

    public_subnet_cidr  = optional(string)
    private_subnet_cidr = optional(string)

    ssh_key_name = optional(string)
    ssh_key = optional(string)
    user_data    = optional(string)

    price_plan_name = optional(string)
    os_password     = optional(string)

    partitions_config = optional(object({
      soft_raid_configs = list(object({
        name      = string
        level     = string
        disk_type = string
      }))
      disk_partitions = list(object({
        mount        = string
        size         = optional(number)
        size_percent = optional(number)
        raid         = string  # должен совпадать с именем одного из soft_raid_configs
        fs_type      = optional(string)
      }))
    }), null)

    timeouts = optional(object({
      create = optional(string, "60m")
      update = optional(string, "60m")
      delete = optional(string, "60m")
    }), { create = "60m", update = "60m", delete = "60m" })
  })

  validation {
    condition = (
      (try(var.server.location_id, null) != null) != (try(var.server.location_name, null) != null)
    )
    error_message = "Укажите ровно один параметр: server.location_id ИЛИ server.location_name."
  }

  validation {
    condition = (
      (try(var.server.configuration_id, null) != null) != (try(var.server.configuration_name, null) != null)
    )
    error_message = "Укажите ровно один параметр: server.configuration_id ИЛИ server.configuration_name."
  }

  validation {
    condition = (
      (try(var.server.os_id, null) != null) != (try(var.server.os_name, null) != null)
    )
    error_message = "Укажите ровно один параметр: server.os_id ИЛИ server.os_name."
  }

  validation {
    condition     = try(var.server.public_subnet_cidr, null) == null || can(regex("/", var.server.public_subnet_cidr))
    error_message = "server.public_subnet_cidr должен быть в формате CIDR (например, 203.0.113.0/24)."
  }

  validation {
    condition     = try(var.server.private_subnet_cidr, null) == null || can(regex("/", var.server.private_subnet_cidr))
    error_message = "server.private_subnet_cidr должен быть в формате CIDR (например, 10.0.0.0/24)."
  }
}
