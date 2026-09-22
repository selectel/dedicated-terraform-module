resource "random_password" "os" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

# ==============================================================================
# LOCALS: ЧАСТЬ 1 (ФЛАГИ И СЫРЫЕ ЗНАЧЕНИЯ)
# ==============================================================================
locals {
  project_id = var.server.project_id

  has_location_name      = var.server.location_name != null
  has_configuration_name = var.server.configuration_name != null
  has_os_name            = var.server.os_name != null
  has_os_version_name    = var.server.os_version_name != null

  location_name_val      = try(var.server.location_name, null)
  configuration_name_val = try(var.server.configuration_name, null)
  os_name_val            = try(var.server.os_name, null)
  os_version_name_val    = try(var.server.os_version_name, null)

  # Сетевые параметры
  public_subnet_cidr    = try(var.server.public_subnet_cidr, null)
  private_subnet_id     = try(var.server.private_subnet_id, null)
  private_subnet_cidr   = try(var.server.private_subnet_cidr, null)
  private_subnet_ip     = try(var.server.private_subnet_ip, null)
  private_vlan_id       = try(var.server.private_vlan_id, null)
  create_private_subnet = try(var.server.create_private_subnet, false)
  add_private_vlan      = try(var.server.add_private_vlan, false)

  # Остальные параметры
  price_plan_name   = try(var.server.price_plan_name, null)
  os_host_name      = try(var.server.os_host_name, null)
  ssh_key_name      = try(var.server.ssh_key_name, null)
  ssh_key           = try(var.server.ssh_key, null)
  user_data         = try(var.server.user_data, null) != null ? file(var.server.user_data) : null
  partitions_config = try(var.server.partitions_config, null)
  timeout_create    = try(var.server.timeouts.create, "60m")
  timeout_update    = try(var.server.timeouts.update, "60m")
  timeout_delete    = try(var.server.timeouts.delete, "60m")
  os_password       = try(var.server.os_password, null) != null ? var.server.os_password : random_password.os.result

  config_available = local.has_configuration_name ? (
    length(try(data.selectel_dedicated_configuration_v1.by_name[0].configurations, [])) > 0
  ) : true
}

# ==============================================================================
# DATA SOURCES: ЧАСТЬ 1 (Не зависят от resolved ID)
# ==============================================================================

data "selectel_dedicated_location_v1" "by_name" {
  count      = local.has_location_name ? 1 : 0
  project_id = local.project_id
  filter {
    name = local.location_name_val
  }
}

# Datasource для получения конфигурации по имени
data "selectel_dedicated_configuration_v1" "by_name" {
  count      = local.has_configuration_name ? 1 : 0
  project_id = local.project_id
  filter {
    name = local.configuration_name_val
  }
}

# Datasource для получения ОС по имени и версии
data "selectel_dedicated_os_v1" "by_name" {
  count      = local.has_os_name && local.config_available ? 1 : 0
  project_id = local.project_id
  filter {
    name             = local.os_name_val
    version_name     = local.has_os_version_name ? var.server.os_version_name : null
    configuration_id = local.config_available ? data.selectel_dedicated_configuration_v1.by_name[0].configurations[0].id : null
    location_id      = local.has_location_name ? data.selectel_dedicated_location_v1.by_name[0].locations[0].id : null
  }
}

data "selectel_dedicated_public_subnet_v1" "public" {
  count      = local.public_subnet_cidr != null ? 1 : 0
  project_id = local.project_id
  filter {
    subnet = local.public_subnet_cidr
  }
}

# ==============================================================================
# LOCALS: ЧАСТЬ 2 (RESOLVED ID из Data Sources Части 1)
# ==============================================================================
locals {
  location_id = local.has_location_name ? (
    length(data.selectel_dedicated_location_v1.by_name) > 0 && length(data.selectel_dedicated_location_v1.by_name[0].locations) > 0 ?
    data.selectel_dedicated_location_v1.by_name[0].locations[0].id : null
  ) : var.server.location_id

  configuration_id = local.has_configuration_name ? (
    length(data.selectel_dedicated_configuration_v1.by_name) > 0 && length(data.selectel_dedicated_configuration_v1.by_name[0].configurations) > 0 ?
    data.selectel_dedicated_configuration_v1.by_name[0].configurations[0].id : null
  ) : var.server.configuration_id

  os_id = local.has_os_name ? (
    length(data.selectel_dedicated_os_v1.by_name) > 0 && length(data.selectel_dedicated_os_v1.by_name[0].os) > 0 ?
    data.selectel_dedicated_os_v1.by_name[0].os[0].id : null
  ) : var.server.os_id

  public_subnet_id = local.public_subnet_cidr != null ? (
    length(data.selectel_dedicated_public_subnet_v1.public) > 0 && length(data.selectel_dedicated_public_subnet_v1.public[0].subnets) > 0 ?
    data.selectel_dedicated_public_subnet_v1.public[0].subnets[0].id : null
  ) : null
}

# ==============================================================================
# DATA SOURCES: ЧАСТЬ 2 (Зависят от local.location_id)
# ==============================================================================
data "selectel_dedicated_private_subnet_v1" "by_cidr" {
  count      = local.private_subnet_cidr != null && !local.create_private_subnet ? 1 : 0
  project_id = local.project_id
  filter {
    subnet      = local.private_subnet_cidr
    location_id = local.location_id
    vlan        = local.private_vlan_id
  }
}

data "selectel_dedicated_private_subnet_v1" "by_ip" {
  count      = local.private_subnet_ip != null && local.private_subnet_cidr == null && local.private_subnet_id == null ? 1 : 0
  project_id = local.project_id
  filter {
    ip          = local.private_subnet_ip
    location_id = local.location_id
  }
}

# ==============================================================================
# LOCALS: ЧАСТЬ 3 (Финальное разрешение Private Subnet ID)
# ==============================================================================
locals {
  private_subnet_id_resolved = (
    local.private_subnet_id != null ? local.private_subnet_id :
    (local.create_private_subnet && length(resource.selectel_dedicated_private_subnet_v1.private) > 0) ? resource.selectel_dedicated_private_subnet_v1.private[0].id :
    (local.private_subnet_cidr != null && length(try(data.selectel_dedicated_private_subnet_v1.by_cidr[0].subnets, [])) > 0) ? data.selectel_dedicated_private_subnet_v1.by_cidr[0].subnets[0].id :
    (local.private_subnet_ip != null && length(try(data.selectel_dedicated_private_subnet_v1.by_ip[0].subnets, [])) > 0) ? data.selectel_dedicated_private_subnet_v1.by_ip[0].subnets[0].id :
    null
  )

  add_private_vlan_flag = (
    local.private_subnet_id_resolved == null && local.add_private_vlan
  )
}

# ==============================================================================
# RESOURCES
# ==============================================================================
resource "selectel_dedicated_private_subnet_v1" "private" {
  count       = local.private_subnet_cidr != null && local.create_private_subnet ? 1 : 0
  location_id = local.location_id
  vlan        = local.private_vlan_id
  subnet      = local.private_subnet_cidr

  timeouts {
    create = local.timeout_create
    delete = local.timeout_delete
  }
}

resource "selectel_dedicated_server_v1" "server" {
  project_id       = local.project_id
  configuration_id = local.configuration_id
  location_id      = local.location_id
  os_id            = local.os_id

  price_plan_name   = local.price_plan_name
  os_host_name      = local.os_host_name
  public_subnet_id  = local.public_subnet_id

  private_subnet_id = local.private_subnet_id_resolved
  private_subnet_ip = local.private_subnet_ip
  add_private_vlan  = local.add_private_vlan_flag

  ssh_key_name = local.ssh_key_name
  ssh_key      = local.ssh_key
  os_password  = local.os_password
  user_data    = local.user_data

  force_update_additional_params = try(var.server.force_update_additional_params, false)

  dynamic "partitions_config" {
    for_each = local.partitions_config != null ? [local.partitions_config] : []
    content {

      # 1. Конфигурация дисков
      dynamic "disk_config" {
        for_each = try(partitions_config.value.disk_configs, [])
        content {
          name      = disk_config.value.name
          disk_type = disk_config.value.disk_type
        }
      }

      # 2. RAID конфигурация
      dynamic "soft_raid_config" {
        for_each = try(partitions_config.value.soft_raid_configs, [])
        content {
          name      = soft_raid_config.value.name
          level     = soft_raid_config.value.level
          disk_type = soft_raid_config.value.disk_type
          count     = try(soft_raid_config.value.count, null)
        }
      }

      # 3. Разделы дисков
      dynamic "disk_partitions" {
        for_each = try(partitions_config.value.disk_partitions, [])
        content {
          mount        = disk_partitions.value.mount
          size         = try(disk_partitions.value.size, null)
          size_percent = try(disk_partitions.value.size_percent, null)
          raid         = try(disk_partitions.value.raid, null)
          fs_type      = try(disk_partitions.value.fs_type, null)
          disk_name    = try(disk_partitions.value.disk_name, null)
        }
      }
    }
  }

  timeouts {
    create = local.timeout_create
    update = local.timeout_update
    delete = local.timeout_delete
  }

  lifecycle {
    precondition {
      condition     = local.config_available
      error_message = "Конфигурация '${var.server.configuration_name}' недоступна в локации '${var.server.location_name}'."
    }
    precondition {
      condition     = local.location_id != null
      error_message = "location_id не резолвится — проверьте server.location_*."
    }
    precondition {
      condition     = local.configuration_id != null
      error_message = "configuration_id не резолвится — проверьте server.configuration_*."
    }
    precondition {
      condition     = local.os_id != null
      error_message = "os_id не резолвится — проверьте server.os_*."
    }
    precondition {
      condition = (
        local.public_subnet_cidr == null ||
        local.public_subnet_id != null
      )
      error_message = "public_subnet_id не получен по CIDR — проверьте server.public_subnet_cidr."
    }
    precondition {
      condition = (
        local.private_subnet_cidr == null ||
        local.create_private_subnet ||
        length(try(data.selectel_dedicated_private_subnet_v1.by_cidr[0].subnets, [])) > 0
      )
      error_message = "Подсеть ${try(local.private_subnet_cidr, "не указана")} не найдена. Укажите create_private_subnet=true для создания или проверьте CIDR/VLAN."
    }
    precondition {
      condition = (
        local.private_subnet_ip == null ||
        local.private_subnet_cidr != null ||
        local.private_subnet_id != null ||
        length(try(data.selectel_dedicated_private_subnet_v1.by_ip[0].subnets, [])) > 0
      )
      error_message = "Не удалось найти подсеть для IP ${try(local.private_subnet_ip, "не указан")}. Укажите CIDR или private_subnet_id."
    }
    
    ignore_changes = [
      ssh_key,
      ssh_key_name,
      power_state
    ]
  }
}
