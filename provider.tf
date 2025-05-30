terraform {
  # required_version = ">= 1.4.0"
  required_version = ">= 1.9.2"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

locals {
  credentials = jsondecode(file(var.credentials_file_path))
  domain_name = lookup(local.credentials, "domain_name", "default") # domain_name이 없을 경우 "default"로 설정
}

provider "openstack" {
  user_name   = local.credentials.user_name
  tenant_name = local.credentials.tenant_name
  password    = local.credentials.password
  auth_url    = local.credentials.auth_url
  region      = local.credentials.region
  domain_name = local.domain_name
}
