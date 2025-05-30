variable "keypair_name" {
  description = "생성할 Keypair의 이름"
  type        = string
}

variable "public_key_path" {
  description = "Public key 파일 경로"
  type        = string
}

variable "create_keypair" {
  description = "새로운 keypair를 생성할지 여부"
  type        = bool
  default     = true
}