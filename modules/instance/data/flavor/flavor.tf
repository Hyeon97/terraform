terraform {
  # required_version = ">= 1.4.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# 일치하는 조건 없으면 다음과 같은 에러 발생
# Error: Your query returned no results. Please change your search criteria and try again.
data "openstack_compute_flavor_v2" "available_flavor" {
  # vcpus  = var.cpu
  # ram    = var.memory
  # region = var.region
  flavor_id = var.flavor_id
}
