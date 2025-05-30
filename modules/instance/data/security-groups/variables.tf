# 보안 그룹 이름을 변수로 설정
variable "security_group_names" {
  description = "보안 그룹의 이름"
  type        = list(string)
  default     = ["default", "ZCCM"]
}