terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# 새로운 Keypair 생성
resource "openstack_compute_keypair_v2" "my_keypair" {
  count      = var.create_keypair ? 1 : 0
  name       = var.keypair_name
  public_key = file(var.public_key_path)
}

# 기존 Keypair 참조
data "openstack_compute_keypair_v2" "existing_keypair" {
  count = var.create_keypair ? 0 : 1
  name  = var.keypair_name
}