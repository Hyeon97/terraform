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

# 통합된 보안 그룹 정보 출력 (기존 + 새로 생성)
output "security_group_list" {
  description = "모든 보안 그룹의 정보 (기존 + 새로 생성)"
  value = merge(
    # 새로 생성된 보안 그룹
    {
      for name, sg in openstack_networking_secgroup_v2.new_security_groups : name => {
        id          = sg.id
        name        = sg.name
        description = sg.description
        source      = "created"
      }
    },
    # 기존 보안 그룹
    {
      for name, sg in data.openstack_networking_secgroup_v2.existing_security_groups : name => {
        id          = sg.id
        name        = sg.name
        description = sg.description
        source      = "existing"
      }
    }
  )
}

# 디버깅용 출력
output "security_group_check_results" {
  description = "보안 그룹 존재 여부 확인 결과"
  value = {
    for name, result in data.external.check_security_groups : name => {
      exists = result.result.exists
      name   = result.result.name
    }
  }
}

# 새로 생성된 보안 그룹만 출력
output "created_security_groups" {
  description = "새로 생성된 보안 그룹 정보"
  value = {
    for name, sg in openstack_networking_secgroup_v2.new_security_groups : name => {
      id   = sg.id
      name = sg.name
    }
  }
}

# 기존 보안 그룹만 출력
output "existing_security_groups" {
  description = "기존에 존재하는 보안 그룹 정보"
  value = {
    for name, sg in data.openstack_networking_secgroup_v2.existing_security_groups : name => {
      id   = sg.id
      name = sg.name
    }
  }
}