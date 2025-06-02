# variable "instance_name" {
#   description = "생성할 인스턴스의 이름"
#   type        = string
# }

# variable "disk_sizes" {
#   description = "인스턴스에 추가할 디스크들의 크기 목록."
#   type        = list(number)
#   default     = []
# }

# variable "volume_type" {
#   description = "디스크 볼륨 유형. [ 'standard' or 'ssd' ]"
#   default     = "standard"
#   type        = string
# }

variable "instance_name" {
  description = "생성할 인스턴스의 이름"
  type        = string
  
  validation {
    condition     = length(var.instance_name) > 0
    error_message = "인스턴스 이름은 비어있을 수 없습니다."
  }
}

variable "disk_sizes" {
  description = "인스턴스에 추가할 디스크들의 크기 목록 (GB)."
  type        = list(number)
  default     = []
  
  validation {
    condition = alltrue([
      for size in var.disk_sizes : size >= 1 && size <= 1000
    ])
    error_message = "디스크 크기는 1GB 이상 1000GB 이하여야 합니다."
  }
}

variable "volume_type" {
  description = "디스크 볼륨 유형. 빈 문자열인 경우 기본 타입 사용"
  type        = string
  default     = ""
  
  validation {
    condition = can(regex("^[a-zA-Z0-9_-]*$", var.volume_type))
    error_message = "볼륨 타입은 영문자, 숫자, 언더스코어, 하이픈만 사용할 수 있습니다."
  }
}