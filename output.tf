# output "instance_info" {
#   # sensitive = true
#   value = module.instance
# }

output "instance_info" {
  description = "생성된 인스턴스의 상세 정보"
  value = {
    id                = module.instance.instance_info.id
    name              = module.instance.instance_info.name
    internal_ip       = module.instance.instance_info.access_ip_v4
    external_ip       = module.instance.floating_ip_info.address
    flavor_name       = module.instance.instance_info.flavor_name
    region            = module.instance.instance_info.region
    security_groups   = module.instance.instance_info.security_groups
    availability_zone = module.instance.instance_info.availability_zone
    created_at        = module.instance.instance_info.created_at
    power_state       = module.instance.instance_info.power_state
    image_id          = module.instance.instance_info.image_id
    network_info = {
      network_id = module.instance.network_info.id
      subnet_id  = module.instance.subnet_info.id
    }
    additional_volumes = [
      for volume in module.instance.volume_info : {
        id   = volume.id
        name = volume.name
        size = volume.size
      }
    ]
  }
  sensitive = false
}

output "connection_info" {
  description = "인스턴스 접속 정보"
  value = {
    ssh_command    = "ssh -i <your-private-key> <username>@${module.instance.floating_ip_info.address}"
    external_ip    = module.instance.floating_ip_info.address
    internal_ip    = module.instance.instance_info.access_ip_v4
    instance_name  = module.instance.instance_info.name
  }
}

output "resource_summary" {
  description = "생성된 리소스 요약"
  value = {
    instance_count     = 1
    additional_volumes = length(var.additional_volumes)
    total_storage_gb   = var.volume_size + sum(var.additional_volumes)
    security_groups    = var.security_group_names
  }
}