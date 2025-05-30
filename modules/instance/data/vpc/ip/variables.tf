# 외부 네트워크 풀 이름
variable "pool_name" {
  description = "The name of the external network pool to allocate the floating IP from."
  type        = string
}

# 인스턴스 이름 변수
variable "instance_name" {
  description = "생성할 인스턴스의 이름."
  type        = string
}