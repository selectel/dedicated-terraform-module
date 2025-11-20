resource "random_password" "os" {
  length              = 24
  special             = true
  override_special    = "!@#%^*-_=+"
}

locals {
  project_id          = var.server.project_id

  location_name      = try(var.server.location_name, null)      != null
  configuration_name = try(var.server.configuration_name, null) != null
  os_name            = try(var.server.os_name, null)            != null
  os_version_name    = try(var.server.os_version_name, null)    != null

  public_subnet_cidr  = try(var.server.public_subnet_cidr, null)
  private_subnet_cidr = try(var.server.private_subnet_cidr, null)

  price_plan_name = try(var.server.price_plan_name, null)
  os_host_name    = try(var.server.os_host_name, null)
  ssh_key_name    = try(var.server.ssh_key_name, null)
  ssh_key         = try(var.server.ssh_key, null)

  user_data = try(var.server.user_data, null) != null ? file(var.server.user_data) : null

  partitions_config = try(var.server.partitions_config, null)

  timeout_create = try(var.server.timeouts.create, "60m")
  timeout_update = try(var.server.timeouts.update, "60m")
  timeout_delete = try(var.server.timeouts.delete, "60m")

  os_password = try(var.server.os_password, null) != null ? var.server.os_password : random_password.os.result
}

# Datasource для получения location по имени
data "selectel_dedicated_location_v1" "by_name" {
  count      = local.location_name ? 1 : 0
  project_id = local.project_id

  filter {
    name = var.server.location_name
  }
}

# Datasource для получения конфигурации по имени
data "selectel_dedicated_configuration_v1" "by_name" {
  count      = local.configuration_name ? 1 : 0
  project_id = local.project_id

  deep_filter = jsonencode({
    name = var.server.configuration_name
  })
}

# Datasource для получения ОС по имени и версии
data "selectel_dedicated_os_v1" "by_name" {
  count      = local.os_name ? 1 : 0
  project_id = local.project_id

  filter {
    name             = var.server.os_name
    version_name     = local.os_version_name ? var.server.os_version_name : null
    configuration_id = data.selectel_dedicated_configuration_v1.by_name[0].configurations[0].id
    location_id      = data.selectel_dedicated_location_v1.by_name[0].locations[0].id
  }
}

data "selectel_dedicated_public_subnet_v1" "public" {
  count      = local.public_subnet_cidr != null ? 1 : 0
  project_id = local.project_id

  filter {
    subnet = local.public_subnet_cidr
  }
}

locals {
  location_id = local.location_name ? (
    data.selectel_dedicated_location_v1.by_name[0].locations[0].id
  ) : (
    var.server.location_id
  )

  configuration_id = local.configuration_name ? (
    data.selectel_dedicated_configuration_v1.by_name[0].configurations[0].id
  ) : (
    var.server.configuration_id
  )

  os_id = local.os_name ? (
    data.selectel_dedicated_os_v1.by_name[0].os[0].id
  ) : (
    var.server.os_id
  )

  public_subnet_id = local.public_subnet_cidr != null ? (
    data.selectel_dedicated_public_subnet_v1.public[0].subnets[0].id
  ) : (
    null
  )
}

resource "selectel_dedicated_server_v1" "server" {
  project_id       = local.project_id
  configuration_id = local.configuration_id
  location_id      = local.location_id
  os_id            = local.os_id

  price_plan_name  = local.price_plan_name
  os_host_name     = local.os_host_name

  public_subnet_id = local.public_subnet_id
  private_subnet   = local.private_subnet_cidr

  ssh_key_name     = local.ssh_key_name
  ssh_key     = local.ssh_key
  os_password      = local.os_password

  user_data        = local.user_data

  dynamic "partitions_config" {
    for_each = local.partitions_config != null ? [local.partitions_config] : []
    content {
      dynamic "soft_raid_config" {
        for_each = partitions_config.value.soft_raid_configs
        content {
          name      = soft_raid_config.value.name
          level     = soft_raid_config.value.level
          disk_type = soft_raid_config.value.disk_type
        }
      }
      dynamic "disk_partitions" {
        for_each = partitions_config.value.disk_partitions
        content {
          mount        = disk_partitions.value.mount
          size         = try(disk_partitions.value.size, null)
          size_percent = try(disk_partitions.value.size_percent, null)
          raid         = disk_partitions.value.raid
          fs_type      = try(disk_partitions.value.fs_type, null)
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
      condition     = (local.public_subnet_cidr == null) || (local.public_subnet_id != null)
      error_message = "public_subnet_id не получен по CIDR — проверьте server.public_subnet_cidr."
    }
    ignore_changes = [
      user_data,
      ssh_key,
      ssh_key_name
    ]
  }
}
