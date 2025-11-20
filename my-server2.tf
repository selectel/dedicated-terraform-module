module "my_server2" {
  source = "./base_modules/baremetal-servers"

  server = {
    project_id = var.project_id

    location_name   = "SPB-2"
    configuration_name = "BL22-NVMe"
    os_name         = "Ubuntu"
    os_version_name = "24.04"
    price_plan_name = "1 day"
    os_host_name    = "my-server2"
    ssh_key         = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYDdFw08hLa54IlUhcXbtY9mS0/4O4Gnv3qPvQ90GeU"
    user_data       = "./user-data/my-script.sh"
    partitions_config = {
      soft_raid_configs = [
        {
          name      = "root-raid"
          level     = "raid1"
          disk_type = "SSD SATA"
        }
      ]
      disk_partitions = [
        {
          mount = "/"
          size  = -1
          fs_type = "ext4"
          raid  = "root-raid"
        }
      ]
    }
  }
}
