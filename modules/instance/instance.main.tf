terraform {
  # required_version = ">= 1.4.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# IP 모듈 호출
# module "floating_ip" {
#   source        = "./data/vpc/ip"
#   pool_name     = var.network_name # 외부 네트워크 풀 이름
#   instance_name = var.instance_name
#   providers = {
#     openstack = openstack
#   }
# }
module "floating_ip" {
  source        = "./data/vpc/ip"
  pool_name     = var.external_network_name  # 외부 네트워크 이름 사용
  instance_name = var.instance_name
  providers = {
    openstack = openstack
  }
}

# 네트워크 모듈 호출
module "network" {
  source       = "./data/vpc/network"
  network_name = var.network_name
  subnet_name  = var.subnet_name
  providers = {
    openstack = openstack
  }
}

# flavor 모듈 호출
module "flavor" {
  source = "./data/flavor"
  # region = var.region
  # cpu    = var.cpu
  # memory = var.memory
  flavor_id = var.flavor_id
  providers = {
    openstack = openstack
  }
}

# 보안 그룹 모듈 호출
# module "security_group" {
#   source               = "./data/security-groups"
#   security_group_names = var.security_group_names
#   providers = {
#     openstack = openstack
#   }
# }
module "security_group" {
  source                  = "./data/security-groups"
  security_group_names    = var.security_group_names
  create_security_groups  = var.create_new_security_groups
  allowed_ssh_cidr        = var.allowed_ssh_cidr
  create_default_rules    = var.create_default_sg_rules
  project_id             = var.project_id
  providers = {
    openstack = openstack
  }
}

# volume 모둘 호출
module "volume" {
  source        = "../volume"
  instance_name = var.instance_name
  disk_sizes    = var.additional_volumes
  volume_type   = var.volume_type
  providers = {
    openstack = openstack
  }
}

# OpenStack VM 생성
resource "openstack_compute_instance_v2" "instance" {
  depends_on  = [ module.network, module.security_group, module.volume, module.flavor]
  name        = var.instance_name
  flavor_name = module.flavor.flavor_info.name

  security_groups = [
    for sg in module.security_group.security_group_list : sg["name"]
  ]
  network {
    uuid = module.network.network_info.id
  }
  block_device {
    uuid                  = var.image_uuid # "image-uuid" # 사용할 이미지 ID
    source_type           = "image"
    volume_size           = var.volume_size # 10 # 디스크 크기 (GB)
    destination_type      = "volume"
    delete_on_termination = true
  }
  user_data = var.user_data_file_path != "" ? base64encode(file(var.user_data_file_path)) : null

   metadata = {
    created_by = "terraform"
    instance_name = var.instance_name
  }
}

# Floating IP를 인스턴스에 연결
# resource "openstack_networking_floatingip_associate_v2" "this" {
#   depends_on  = [module.floating_ip, openstack_compute_instance_v2.instance]
#   floating_ip = module.floating_ip.floating_ip_info.address
#   instance_id = openstack_compute_instance_v2.instance.id
#   # port_id = module.floating_ip.floating_ip_info.port_id
#   # port_id       = openstack_compute_instance_v2.instance.access_ip_v4
#   # instance_id = openstack_compute_instance_v2.instance.id # 인스턴스 ID를 변수로 받음
# }

# 인스턴스의 첫 번째 포트 정보 가져오기
data "openstack_networking_port_v2" "instance_port" {
  depends_on = [openstack_compute_instance_v2.instance]
  device_id  = openstack_compute_instance_v2.instance.id
  
  # 첫 번째 포트만 선택하기 위한 필터
  network_id = module.network.network_info.id
}

# Floating IP를 인스턴스 포트에 연결
resource "openstack_networking_floatingip_associate_v2" "this" {
  depends_on  = [module.floating_ip, data.openstack_networking_port_v2.instance_port]
  floating_ip = module.floating_ip.floating_ip_info.address
  port_id     = data.openstack_networking_port_v2.instance_port.id
}


# 추가 디스크 인스턴스에 연결
resource "openstack_compute_volume_attach_v2" "volume_attach" {
  # depends_on  = [openstack_compute_instance_v2.instance]
  # count       = length(module.volume.additional_disk_info_list)
  depends_on  = [openstack_compute_instance_v2.instance, module.volume]
  count       = length(var.additional_volumes)
  instance_id = openstack_compute_instance_v2.instance.id
  volume_id   = module.volume.additional_disk_info_list[count.index].id

}