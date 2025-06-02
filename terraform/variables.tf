variable "credentials_file_path" {
  description = "openstack 인증정보 파일 경로"
  type        = string
  
  validation {
    condition     = can(file(var.credentials_file_path))
    error_message = "지정된 인증정보 파일이 존재하지 않습니다."
  }
}

variable "network_name" {
  description = "인스턴스에 연결할 네트워크 이름."
  type        = string
  
  validation {
    condition     = length(var.network_name) > 0
    error_message = "네트워크 이름은 비어있을 수 없습니다."
  }
}

variable "subnet_name" {
  description = "인스턴스에 연결할 서브넷 이름."
  type        = string
  
  validation {
    condition     = length(var.subnet_name) > 0
    error_message = "서브넷 이름은 비어있을 수 없습니다."
  }
}

variable "instance_name" {
  description = "생성할 인스턴스의 이름."
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.instance_name))
    error_message = "인스턴스 이름은 영문자, 숫자, 하이픈만 사용할 수 있습니다."
  }
}

variable "image_uuid" {
  description = "인스턴스에 사용할 이미지의 UUID."
  type        = string
  
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.image_uuid))
    error_message = "올바른 UUID 형식이 아닙니다."
  }
}

variable "flavor_id" {
  description = "인스턴스에 사용할 flavor ID."
  type        = string
  
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.flavor_id))
    error_message = "올바른 flavor UUID 형식이 아닙니다."
  }
}

variable "volume_size" {
  description = "인스턴스에 연결할 볼륨 크기 (GB 단위)."
  type        = number
  default     = 10
  
  validation {
    condition     = var.volume_size >= 1 && var.volume_size <= 1000
    error_message = "볼륨 크기는 1GB 이상 1000GB 이하여야 합니다."
  }
}

variable "region" {
  description = "OpenStack 리전"
  type        = string
  default     = "RegionOne"
}

variable "cpu" {
  description = "cpu 갯수"
  type        = number
  default     = 1
  
  validation {
    condition     = var.cpu >= 1 && var.cpu <= 64
    error_message = "CPU 수는 1개 이상 64개 이하여야 합니다."
  }
}

variable "memory" {
  description = "memory 크기 (단위: MB)"
  type        = number
  default     = 512
  
  validation {
    condition     = var.memory >= 512 && var.memory <= 131072
    error_message = "메모리는 512MB 이상 128GB 이하여야 합니다."
  }
}

variable "security_group_names" {
  description = "인스턴스에 적용할 보안 그룹 이름."
  type        = list(string)
  default     = ["default"]
  
  validation {
    condition     = length(var.security_group_names) > 0
    error_message = "최소 하나의 보안 그룹은 지정해야 합니다."
  }
}

variable "user_data_file_path" {
  description = "인스턴스에 적용할 user data file path."
  type        = string
  default     = ""
  
  validation {
    condition = var.user_data_file_path == "" || can(file(var.user_data_file_path))
    error_message = "지정된 user data 파일이 존재하지 않습니다."
  }
}

variable "additional_volumes" {
  description = "인스턴스에 추가할 추가디스크 크기 목록 (GB)."
  type        = list(number)
  default     = []
  
  validation {
    condition = alltrue([
      for size in var.additional_volumes : size >= 1 && size <= 1000
    ])
    error_message = "추가 볼륨 크기는 1GB 이상 1000GB 이하여야 합니다."
  }
}

variable "external_network_name" {
  description = "Floating IP를 할당받을 외부 네트워크 이름"
  type        = string
  default     = "external"
}

# 보안 그룹 관련 누락된 변수들 추가
variable "create_new_security_groups" {
  description = "존재하지 않는 보안 그룹을 자동으로 생성할지 여부"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidr" {
  description = "SSH 접근을 허용할 CIDR 블록"
  type        = string
  default     = "0.0.0.0/0"
  
  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "올바른 CIDR 형식이 아닙니다."
  }
}

variable "create_default_sg_rules" {
  description = "기본 보안 룰을 생성할지 여부 (SSH, ICMP, egress)"
  type        = bool
  default     = true
}

variable "volume_type" {
  description = "디스크 볼륨 유형. 빈 문자열인 경우 기본 타입 사용"
  type        = string
  default     = ""
}

# Keypair 관련 변수 추가
variable "use_keypair" {
  description = "SSH keypair 사용 여부"
  type        = bool
  default     = false
}

variable "keypair_name" {
  description = "생성할 또는 사용할 keypair 이름"
  type        = string
  default     = ""
}

variable "public_key_path" {
  description = "Public key 파일 경로 (keypair 생성 시 필요)"
  type        = string
  default     = ""
  
  validation {
    condition = var.public_key_path == "" || can(file(var.public_key_path))
    error_message = "지정된 public key 파일이 존재하지 않습니다."
  }
}

variable "create_new_keypair" {
  description = "새로운 keypair를 생성할지 여부 (false인 경우 기존 keypair 사용)"
  type        = bool
  default     = true
}

# variable "project_id" {
#   description = "OpenStack 프로젝트 ID (tenant_id)"
#   type        = string
  
#   validation {
#     condition     = can(regex("^[0-9a-f]{32}$", var.project_id))
#     error_message = "올바른 OpenStack 프로젝트 ID 형식이 아닙니다 (32자리 hex)."
#   }
# }