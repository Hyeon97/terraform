# 보안 그룹 ID를 출력 (새로 생성된 그룹이든, 기존 그룹이든 동일한 형식으로 출력)
# output "security_group_ids" {
#   value = data.openstack_networking_secgroup_v2.existing_secgroup
# }

output "security_group_list" {
  description = "IDs of the retrieved security groups"
  value       = { for name, sg in data.openstack_networking_secgroup_v2.existing_secgroups : name => sg }
}

# Outputs:

# security_group_ids = {
#   "all_tags" = toset([])
#   "description" = ""
#   "id" = "5a4d0e11-ffa3-40a5-b6a3-9be298633e47"
#   "name" = "ZCM"
#   "region" = "RegionOne"
#   "secgroup_id" = tostring(null)
#   "stateful" = true
#   "tags" = toset(null) /* of string */
#   "tenant_id" = "451ba464ae8a43d0af140f27085e014e"
# }