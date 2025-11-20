module "my_server1" {
  source = "./base_modules/baremetal-servers"

  server = {
    project_id = var.project_id

    location_name   = "SPB-2"
    configuration_name = "BL22-NVMe"
    os_name         = "Ubuntu"
    os_version_name = "24.04"
    price_plan_name = "1 day"
    os_host_name    = "my-server1"
    ssh_key_name    = "ivanov.v"
    user_data       = "./user-data/my-user-data.yml"
    partitions_config = {
      soft_raid_configs = [
        {
          name      = "first-raid"
          level     = "raid1"
          disk_type = "SSD SATA"
        },
        {
          name      = "second-raid"
          level     = "raid0"
          disk_type = "SSD NVMe"
        }
      ]
      disk_partitions = [
        {
          mount = "/boot"
          size  = 1
          raid  = "first-raid"
        },
        {
          mount        = "swap"
          size_percent = 10.5
          raid         = "first-raid"
        },
        {
          mount = "/"
          size  = -1
          raid  = "first-raid"
        },
        {
          mount   = "/second_folder"
          size    = 400
          raid    = "second-raid"
          fs_type = "xfs"
        }
      ]
    }
  }
}
