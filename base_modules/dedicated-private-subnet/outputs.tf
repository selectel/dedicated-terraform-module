output "id" {
  description = "ID созданной или найденной приватной подсети"
  value = var.create ? (
    resource.selectel_dedicated_private_subnet_v1.new[0].id
  ) : (
    data.selectel_dedicated_private_subnet_v1.existing[0].subnets[0].id
  )
}

output "cidr" {
  description = "CIDR подсети"
  value       = var.cidr
}

output "vlan_id" {
  description = "VLAN ID подсети"
  value       = var.vlan_id
}

