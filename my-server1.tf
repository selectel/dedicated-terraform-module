module "my_server1" {
  source = "./base_modules/baremetal-servers"

  server = {
    project_id         = var.project_id
    location_name      = "MSK-7"
    configuration_name = "EL49-NVMe-10GE"
    os_name            = "Ubuntu"
    os_version_name    = "24.04 LTS"
    price_plan_name    = "1 month"
    os_host_name       = "my-server1"
    ssh_key_name       = "ivanov.v"
    user_data          = "./user-data/my-user-data.yml"

    private_vlan_id       = "10167"
    private_subnet_cidr   = "10.10.14.0/24" # Такая подсеть уже есть
    create_private_subnet = true
    private_subnet_ip     = "10.10.14.105"

    partitions_config = {
      disk_configs = [
        {
          name      = "system"
          disk_type = "SSD NVMe M.2"
        },
        {
          name      = "data"
          disk_type = "SSD NVMe M.2"
        }
      ]

      disk_partitions = [
        {
          disk_name = "system"
          mount     = "/boot"
          size      = 1
        },
        {
          disk_name = "system"
          mount     = "/home"
          size      = 150
        },
        {
          disk_name = "system"
          mount     = "/"
          size      = -1
        },
        {
          disk_name = "data"
          mount     = "/var"
          size      = -1
        }
      ]
    }
  }
}
