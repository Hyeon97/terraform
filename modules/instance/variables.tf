# 네트워크 이름 변수 (네트워크 모듈에서 사용)
variable "network_name" {
  description = "인스턴스에 연결할 네트워크 이름."
  type        = string
}

# 서브넷 이름 변수 (네트워크 모듈에서 사용)
variable "subnet_name" {
  description = "인스턴스에 연결할 서브넷 이름."
  type        = string
}

# 인스턴스 이름 변수
variable "instance_name" {
  description = "생성할 인스턴스의 이름."
  type        = string
}

# 이미지 UUID 변수
variable "image_uuid" {
  description = "인스턴스에 사용할 이미지의 UUID."
  type        = string
}

# 볼륨 크기 변수
variable "volume_size" {
  description = "인스턴스에 연결할 볼륨 크기 (GB 단위)."
  type        = number
  default     = 10
}

variable "region" {
  type    = string
  default = "RegionOne"
}

variable "cpu" {
  description = "cpu 갯수"
  type        = number
}

variable "memory" {
  description = "memory 크기 (단위: MB)"
  type        = number
}

variable "security_group_names" {
  description = "인스턴스에 적용할 보안 그룹 이름."
  type        = list(string)
}

variable "user_data_file_path" {
  description = "인스턴스에 적용할 user data file path."
  type        = string
  default     = ""
}

variable "additional_volumes" {
  description = "인스턴스에 추가할 추가디스크."
  type        = list(number)
  default     = []
}

variable "flavor_id" {
  description = "인스턴스에 사용할 flavor ID."
  type        = string
}

# 보안 그룹 관련 변수들
variable "auto_create_security_groups" {
  description = "존재하지 않는 보안 그룹을 자동으로 생성할지 여부"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidr" {
  description = "SSH 접근을 허용할 CIDR 블록"
  type        = string
  default     = "0.0.0.0/0"
}

variable "create_default_sg_rules" {
  description = "기본 보안 룰을 생성할지 여부"
  type        = bool
  default     = true
}

variable "volume_type" {
  description = "디스크 볼륨 유형"
  type        = string
  default     = ""
}