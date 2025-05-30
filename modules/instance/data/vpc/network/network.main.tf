terraform {
  # required_version = ">= 1.4.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# 네트워크가 존재하는지 확인
data "openstack_networking_network_v2" "existing_network" {
  name = var.network_name
  # count = length([for net in openstack_networking_network_v2.my_network : net.name == var.network_name ? 1 : 0]) > 0 ? 1 : 0
}

# 서브넷이 존재하는지 확인
data "openstack_networking_subnet_v2" "existing_subnet" {
  name = var.subnet_name
  # count = length([for sub in openstack_networking_subnet_v2.my_subnet : sub.name == var.subnet_name ? 1 : 0]) > 0 ? 1 : 0
}

# # 네트워크 생성 (존재하지 않으면)
# resource "openstack_networking_network_v2" "new_network" {
#   count = data.openstack_networking_network_v2.existing_network.count == 0 ? 1 : 0

#   name           = var.network_name
#   admin_state_up = true
# }

# # 서브넷 생성 (존재하지 않으면)
# resource "openstack_networking_subnet_v2" "new_subnet" {
#   count = data.openstack_networking_subnet_v2.existing_subnet.count == 0 ? 1 : 0

#   name = var.subnet_name
#   network_id = coalesce(
#     try(data.openstack_networking_network_v2.existing_network[0].id),
#     openstack_networking_network_v2.new_network[0].id
#   )
#   cidr       = var.cidr_block
#   ip_version = 4
# }