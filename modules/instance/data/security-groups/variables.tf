# # 보안 그룹 이름을 변수로 설정
# variable "security_group_names" {
#   description = "보안 그룹의 이름"
#   type        = list(string)
#   default     = ["default", "ZCCM"]
# }

variable "security_group_names" {
  description = "보안 그룹의 이름 목록"
  type        = list(string)
  default     = ["default"]
  
  validation {
    condition     = length(var.security_group_names) > 0
    error_message = "최소 하나의 보안 그룹은 지정해야 합니다."
  }
}

variable "auto_create_missing" {
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

variable "create_default_rules" {
  description = "기본 보안 룰을 생성할지 여부 (SSH, ICMP, egress)"
  type        = bool
  default     = true
}