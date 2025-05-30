terraform {
  # required_version = ">= 1.4.0"
  required_version = ">= 1.9.2"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

# locals {
#   credentials = jsondecode(file(var.credentials_file_path))
#   domain_name = lookup(local.credentials, "domain_name", "default") # domain_name이 없을 경우 "default"로 설정
# }

# provider "openstack" {
#   user_name   = local.credentials.user_name
#   tenant_name = local.credentials.tenant_name
#   password    = local.credentials.password
#   auth_url    = local.credentials.auth_url
#   region      = local.credentials.region
#   domain_name = local.domain_name
# }


locals {
  credentials = jsondecode(file(var.credentials_file_path))
  domain_name = lookup(local.credentials, "domain_name", "default")
  
  # 인증 정보 검증
  required_fields = ["user_name", "tenant_name", "password", "auth_url", "region"]
  missing_fields = [
    for field in local.required_fields : field
    if !contains(keys(local.credentials), field)
  ]
}

# 인증 정보 누락 검증
resource "null_resource" "validate_credentials" {
  count = length(local.missing_fields) > 0 ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'Missing required fields in credentials: ${join(", ", local.missing_fields)}' && exit 1"
  }
}

provider "openstack" {
  user_name         = local.credentials.user_name
  tenant_name       = local.credentials.tenant_name
  password          = local.credentials.password
  auth_url          = local.credentials.auth_url
  region            = local.credentials.region
  domain_name       = local.domain_name
  # Load Balancer as a Service (LBaaS) 사용 시 Octavia 서비스 활용
  # true: 최신 Octavia LBaaS v2 API 사용
  # false: 구형 Neutron LBaaS v1/v2 API 사용
  # use_octavia       = true
  # 인증 시점 제어
  # false: Terraform 계획(plan) 단계에서 즉시 인증 수행
  # true: 실제 리소스 조작 시점에 인증 수행
  delayed_auth      = false
  # 토큰 만료 시 자동 재인증 허용
  # true: 토큰 만료 시 자동으로 재인증 수행
  # false: 토큰 만료 시 오류 발생
  allow_reauth      = true
  
  # 타임아웃 설정
  max_retries = 3
}