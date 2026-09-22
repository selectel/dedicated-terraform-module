module "my_server2" {
  source = "./base_modules/baremetal-servers"

  server = {
    project_id         = var.project_id
    location_name      = "SPB-2"
    configuration_name = "EL12-SSD"
    os_name            = "Ubuntu"
    os_version_name    = "24.04 LTS"
    price_plan_name    = "1 month"
    os_host_name       = "my-server2"
    ssh_key            = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYDdFw08hLa54IlUhcXbtY9mS0/4O4Gnv3qPvQ90GeU"
    user_data          = "./user-data/my-script.sh"

    private_subnet_cidr   = "10.10.15.0/24"
    private_subnet_ip     = "10.10.15.106"
    private_vlan_id       = "1218" # Другой VLAN для другой локации
    create_private_subnet = true # Создаем новую подсеть (если она уже есть закомментировать)

    force_update_additional_params = true
    partitions_config = {
      soft_raid_configs = [
        {
          name      = "first-raid"
          level     = "raid1"
          disk_type = "SSD SATA"
          count = 2
        },
        {
          name      = "second-raid"
          level     = "raid1"
          disk_type = "HDD SATA"
          count = 2
        }
      ]

      disk_partitions = [
        {
          disk_name = "system"
          mount     = "/"
          size      = -1
          raid      = "first-raid"
        },
        {
          disk_name = "data"
          mount     = "/home"
          size      = -1
          raid      = "second-raid"
        }
      ]
    }
  }
}
