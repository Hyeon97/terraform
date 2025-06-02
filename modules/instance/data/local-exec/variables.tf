variable "instance_name" {
  description = "인스턴스 이름"
  type        = string
}

variable "instance_id" {
  description = "인스턴스 ID"
  type        = string
}

variable "external_ip" {
  description = "외부 IP 주소"
  type        = string
}

variable "internal_ip" {
  description = "내부 IP 주소"
  type        = string
}

variable "flavor_name" {
  description = "인스턴스 flavor 이름"
  type        = string
}

variable "image_uuid" {
  description = "이미지 UUID"
  type        = string
}

variable "security_groups" {
  description = "보안 그룹 목록"
  type        = list(string)
}

variable "keypair_name" {
  description = "키페어 이름"
  type        = string
  default     = ""
}

variable "use_keypair" {
  description = "키페어 사용 여부"
  type        = bool
  default     = false
}

variable "network_name" {
  description = "네트워크 이름"
  type        = string
}

variable "subnet_name" {
  description = "서브넷 이름"
  type        = string
}

variable "additional_volumes" {
  description = "추가 볼륨 정보"
  type        = list(object({
    id   = string
    name = string
    size = number
  }))
  default = []
}