output "servers" {
  description = "Информация по всем созданным серверам"
  value = {
    my_server1 = {
      server_id    = module.my_server1.server_id
      server_name  = module.my_server1.server_name
      public_ip    = module.my_server1.public_ip
      private_ip   = module.my_server1.private_ip
      private_vlan = module.my_server1.private_vlan
    }
    my_server2 = {
      server_id    = module.my_server2.server_id
      server_name  = module.my_server2.server_name
      public_ip    = module.my_server2.public_ip
      private_ip   = module.my_server2.private_ip
      private_vlan = module.my_server2.private_vlan
    }
  }
}
