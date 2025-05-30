variable "instance_name" {
  description = "생성할 인스턴스의 이름"
  type        = string
}

variable "disk_sizes" {
  description = "인스턴스에 추가할 디스크들의 크기 목록."
  type        = list(number)
  default     = []
}

variable "volume_type" {
  description = "디스크 볼륨 유형. [ 'standard' or 'ssd' ]"
  default     = "standard"
  type        = string
}
