# terraform {
#   required_providers {
#     openstack = {
#       source = "terraform-provider-openstack/openstack"
#     }
#   }
# }

# # # 보안 그룹이 없으면 생성, 있으면 가져오기
# # resource "openstack_networking_secgroup_v2" "new_secgroup" {
# #   count       = length(var.group_names)
# #   name        = var.group_names[count.index]
# #   description = "Auto-created security group for ${var.group_names[count.index]}"
# # }

# # 보안 그룹 데이터를 가져오기 (기존에 있는 그룹을 가져오거나, 위에서 생성된 그룹 사용)
# data "openstack_networking_secgroup_v2" "existing_secgroups" {
#   for_each = toset(var.security_group_names) # 각 그룹 이름에 대해 반복 실행
#   name     = each.key
# }

terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# 1. 외부 명령으로 보안 그룹 존재 여부 확인
data "external" "check_security_groups" {
  for_each = toset(var.security_group_names)
  
  program = ["bash", "-c", <<-EOT
    if openstack security group show "${each.key}" >/dev/null 2>&1; then
      echo '{"exists":"true","name":"${each.key}"}'
    else
      echo '{"exists":"false","name":"${each.key}"}'
    fi
  EOT
  ]
}

# 2. 존재하지 않는 보안 그룹만 생성
resource "openstack_networking_secgroup_v2" "new_security_groups" {
  for_each = {
    for name in var.security_group_names : name => name
    if data.external.check_security_groups[name].result.exists == "false"
  }
  
  name        = each.key
  description = "Auto-created security group '${each.key}' by Terraform"
  
  tags = ["terraform-managed", "auto-created"]
}

# 3. 존재하는 보안 그룹 정보 가져오기
data "openstack_networking_secgroup_v2" "existing_security_groups" {
  for_each = {
    for name in var.security_group_names : name => name
    if data.external.check_security_groups[name].result.exists == "true"
  }
  
  name = each.key
}

# 4. 새로 생성된 보안 그룹에만 SSH 룰 추가
resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  for_each = var.create_default_rules ? openstack_networking_secgroup_v2.new_security_groups : {}
  
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.allowed_ssh_cidr
  security_group_id = each.value.id
  description       = "SSH access - Terraform managed"
}

# 5. 새로 생성된 보안 그룹에만 ICMP 룰 추가
resource "openstack_networking_secgroup_rule_v2" "icmp_ingress" {
  for_each = var.create_default_rules ? openstack_networking_secgroup_v2.new_security_groups : {}
  
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = each.value.id
  description       = "ICMP access - Terraform managed"
}