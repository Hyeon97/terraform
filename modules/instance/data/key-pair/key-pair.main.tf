terraform {
  # required_version = ">= 1.4.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# Keypair 생성
resource "openstack_compute_keypair_v2" "my_keypair" {
  name       = var.keypair_name          # 변수를 사용하여 keypair 이름을 동적으로 입력받음
  public_key = file(var.public_key_path) # 변수를 사용하여 public key 경로를 동적으로 입력받음
}