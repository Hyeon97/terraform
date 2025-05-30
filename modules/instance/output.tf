output "instance_info" {
  description = "인스턴스 상세 정보"
  value = {
    id               = openstack_compute_instance_v2.instance.id
    name             = openstack_compute_instance_v2.instance.name
    access_ip_v4     = openstack_compute_instance_v2.instance.access_ip_v4
    access_ip_v6     = openstack_compute_instance_v2.instance.access_ip_v6
    flavor_name      = openstack_compute_instance_v2.instance.flavor_name
    region           = openstack_compute_instance_v2.instance.region
    key_pair         = openstack_compute_instance_v2.instance.key_pair
    security_groups  = openstack_compute_instance_v2.instance.security_groups
    availability_zone = openstack_compute_instance_v2.instance.availability_zone
    created_at       = openstack_compute_instance_v2.instance.created
    updated_at       = openstack_compute_instance_v2.instance.updated
    power_state      = openstack_compute_instance_v2.instance.power_state
    image_id         = openstack_compute_instance_v2.instance.image_id
    metadata         = openstack_compute_instance_v2.instance.metadata
    user_data        = openstack_compute_instance_v2.instance.user_data
  }
  sensitive = false
}

# Floating IP 정보 출력 추가
output "floating_ip_info" {
  description = "할당된 Floating IP 정보"
  value = {
    address     = module.floating_ip.floating_ip_info.address
    id          = module.floating_ip.floating_ip_info.id
    pool        = module.floating_ip.floating_ip_info.pool
    description = module.floating_ip.floating_ip_info.description
    tags        = module.floating_ip.floating_ip_info.tags
  }
}

# 네트워크 정보 출력 추가
output "network_info" {
  description = "네트워크 정보"
  value = {
    id   = module.network.network_info.id
    name = module.network.network_info.name
    mtu  = module.network.network_info.mtu
  }
}

# 서브넷 정보 출력 추가
output "subnet_info" {
  description = "서브넷 정보"
  value = {
    id         = module.network.subnet_info.id
    name       = module.network.subnet_info.name
    cidr       = module.network.subnet_info.cidr
    gateway_ip = module.network.subnet_info.gateway_ip
  }
}

# 볼륨 정보 출력 추가
output "volume_info" {
  description = "추가 볼륨 정보"
  value       = module.volume.additional_disk_info_list
}

# Keypair 정보 출력 추가
output "keypair_info" {
  description = "사용된 Keypair 정보"
  value = var.use_keypair ? (
    length(module.keypair) > 0 ? module.keypair[0].keypair_info : null
  ) : null
}