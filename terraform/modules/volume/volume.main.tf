terraform {
  # required_version = ">= 1.4.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# resource "openstack_blockstorage_volume_v3" "additional_disk" {
#   count       = length(var.disk_sizes)
#   name        = "${var.instance_name}-disk-${count.index + 1}"
#   size        = var.disk_sizes[count.index] # Pass disk sizes via variable
#   description = "Additional volume for ${var.instance_name}"
#   # volume_type = var.volume_type
# }

# 볼륨 타입이 지정된 경우에만 검증
locals {
  # 볼륨 타입이 빈 문자열이 아닌 경우에만 설정
  validated_volume_type = var.volume_type != "" && var.volume_type != null ? var.volume_type : null
}

resource "openstack_blockstorage_volume_v3" "additional_disk" {
  count       = length(var.disk_sizes)
  name        = "${var.instance_name}-disk-${count.index + 1}"
  size        = var.disk_sizes[count.index]
  description = "Additional volume for ${var.instance_name}"
  volume_type = local.validated_volume_type
  
  # 볼륨 메타데이터 추가
  metadata = {
    created_by    = "terraform"
    instance_name = var.instance_name
    disk_index    = count.index + 1
  }
  
  # 볼륨 삭제 방지 (선택사항)
  lifecycle {
    prevent_destroy = false
  }
}