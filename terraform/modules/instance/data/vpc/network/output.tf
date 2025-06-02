# 네트워크 정보 출력
output "network_info" {
  value = data.openstack_networking_network_v2.existing_network
}

# 서브넷 정보 출력
output "subnet_info" {
  value = data.openstack_networking_subnet_v2.existing_subnet
}

# Outputs:

# network_info = {
#   "admin_state_up" = "true"
#   "all_tags" = toset([])
#   "availability_zone_hints" = tolist([])
#   "description" = ""
#   "dns_domain" = ""
#   "external" = false
#   "id" = "6e48c419-4d41-480b-bf1f-b8bc5477b146"
#   "matching_subnet_cidr" = tostring(null)
#   "mtu" = 1450
#   "name" = "internal-network"
#   "network_id" = tostring(null)
#   "region" = "RegionOne"
#   "segments" = toset([
#     {
#       "network_type" = "vxlan"
#       "physical_network" = ""
#       "segmentation_id" = 234
#     },
#   ])
#   "shared" = "false"
#   "status" = tostring(null)
#   "subnets" = tolist([
#     "3520f090-ce61-48ca-947e-ce466f489d19",
#   ])
#   "tags" = toset(null) /* of string */
#   "tenant_id" = "451ba464ae8a43d0af140f27085e014e"
#   "transparent_vlan" = false
# }

# subnet_info = {
#   "all_tags" = toset([])
#   "allocation_pools" = tolist([
#     {
#       "end" = "10.0.255.254"
#       "start" = "10.0.0.2"
#     },
#   ])
#   "cidr" = "10.0.0.0/16"
#   "description" = ""
#   "dhcp_enabled" = tobool(null)
#   "dns_nameservers" = toset([])
#   "dns_publish_fixed_ip" = false
#   "enable_dhcp" = true
#   "gateway_ip" = "10.0.0.1"
#   "host_routes" = tolist([])
#   "id" = "3520f090-ce61-48ca-947e-ce466f489d19"
#   "ip_version" = 4
#   "ipv6_address_mode" = ""
#   "ipv6_ra_mode" = ""
#   "name" = "internal"
#   "network_id" = "6e48c419-4d41-480b-bf1f-b8bc5477b146"
#   "region" = "RegionOne"
#   "service_types" = toset([])
#   "subnet_id" = tostring(null)
#   "subnetpool_id" = ""
#   "tags" = toset(null) /* of string */
#   "tenant_id" = "451ba464ae8a43d0af140f27085e014e"
# }