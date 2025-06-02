# # 보안 그룹 ID를 출력 (새로 생성된 그룹이든, 기존 그룹이든 동일한 형식으로 출력)
# # output "security_group_ids" {
# #   value = data.openstack_networking_secgroup_v2.existing_secgroup
# # }

# output "security_group_list" {
#   description = "IDs of the retrieved security groups"
#   value       = { for name, sg in data.openstack_networking_secgroup_v2.existing_secgroups : name => sg }
# }

# # Outputs:

# # security_group_ids = {
# #   "all_tags" = toset([])
# #   "description" = ""
# #   "id" = "5a4d0e11-ffa3-40a5-b6a3-9be298633e47"
# #   "name" = "ZCM"
# #   "region" = "RegionOne"
# #   "secgroup_id" = tostring(null)
# #   "stateful" = true
# #   "tags" = toset(null) /* of string */
# #   "tenant_id" = "451ba464ae8a43d0af140f27085e014e"
# # }

# 통합된 보안 그룹 정보 출력 (생성된 것 또는 기존 것)
output "security_group_list" {
  description = "사용할 보안 그룹의 정보"
  value = var.create_security_groups ? {
    # 새로 생성된 보안 그룹
    for name, sg in openstack_networking_secgroup_v2.new_security_groups : name => {
      id          = sg.id
      name        = sg.name
      description = sg.description
      source      = "created"
    }
  } : {
    # 기존 보안 그룹
    for name, sg in data.openstack_networking_secgroup_v2.existing_security_groups : name => {
      id          = sg.id
      name        = sg.name
      description = sg.description
      source      = "existing"
    }
  }
}

# 생성 여부 정보
output "security_group_creation_info" {
  description = "보안 그룹 생성 여부와 상태"
  value = {
    create_mode     = var.create_security_groups
    group_names     = var.security_group_names
    created_count   = var.create_security_groups ? length(openstack_networking_secgroup_v2.new_security_groups) : 0
    existing_count  = !var.create_security_groups ? length(data.openstack_networking_secgroup_v2.existing_security_groups) : 0
  }
}