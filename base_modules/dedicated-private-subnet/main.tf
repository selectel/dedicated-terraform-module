## === Поиск существующей подсети (если create = false) ===
data "selectel_dedicated_private_subnet_v1" "existing" {
  count = var.create ? 0 : 1

  project_id = var.project_id
  filter {
    subnet      = var.cidr
    vlan        = var.vlan_id
    location_id = var.location_id  # ← передаём напрямую
  }
}

# === Создание новой подсети (если create = true) ===
resource "selectel_dedicated_private_subnet_v1" "new" {
  count = var.create ? 1 : 0

  location_id = var.location_id  # ← передаём напрямую
  vlan        = var.vlan_id
  subnet      = var.cidr

  timeouts {
    create = try(var.timeouts.create, "10m")
    delete = try(var.timeouts.delete, "10m")
  }
}

locals {
  found = var.create ? true : (
    length(data.selectel_dedicated_private_subnet_v1.existing[0].subnets) > 0
  )
}

resource "terraform_data" "validation" {
  count = var.create ? 0 : 1

  lifecycle {
    precondition {
      condition     = local.found
      error_message = "Подсеть ${var.cidr} с VLAN ${var.vlan_id} не найдена в локации ${var.location_id}. Укажите create=true для создания новой."
    }
  }
}
