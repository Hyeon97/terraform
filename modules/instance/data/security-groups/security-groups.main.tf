terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# # 보안 그룹이 없으면 생성, 있으면 가져오기
# resource "openstack_networking_secgroup_v2" "new_secgroup" {
#   count       = length(var.group_names)
#   name        = var.group_names[count.index]
#   description = "Auto-created security group for ${var.group_names[count.index]}"
# }

# 보안 그룹 데이터를 가져오기 (기존에 있는 그룹을 가져오거나, 위에서 생성된 그룹 사용)
data "openstack_networking_secgroup_v2" "existing_secgroups" {
  for_each = toset(var.security_group_names) # 각 그룹 이름에 대해 반복 실행
  name     = each.key
}