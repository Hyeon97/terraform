terraform {
  # required_version = ">= 1.4.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# Floating IP 생성
resource "openstack_networking_floatingip_v2" "this" {
  pool        = var.pool_name               # 외부 네트워크 풀 이름을 변수로 받음
  description = "${var.instance_name}`s IP" # IP에 대한 설명을 추가
  tags        = [var.instance_name]         # IP에 태그를 추가 (리스트 형태로)
}