# 할당된 Floating IP 정보 출력
output "floating_ip_info" {
  description = "The allocated floating IP Info."
  value       = openstack_networking_floatingip_v2.this
}

# floating_ip_info = {
#   "address" = "192.168.2.196"
#   "all_tags" = toset([
#     "HSTEST",
#   ])
#   "description" = "HSTEST`s IP"
#   "dns_domain" = ""
#   "dns_name" = ""
#   "fixed_ip" = ""
#   "id" = "3a6b17ba-a86a-4b71-ba5c-fdde225c41ff"
#   "pool" = "external"
#   "port_id" = ""
#   "region" = "RegionOne"
#   "subnet_id" = tostring(null)
#   "subnet_ids" = tolist(null) /* of string */
#   "tags" = toset([
#     "HSTEST",
#   ])
#   "tenant_id" = "451ba464ae8a43d0af140f27085e014e"
#   "timeouts" = null /* object */
#   "value_specs" = tomap(null) /* of string */
# }