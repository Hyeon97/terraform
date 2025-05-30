# variable "region" {
#   type    = string
#   default = "RegionOne"
# }

# variable "cpu" {
#   description = "cpu 갯수"
#   type        = number
# }

# variable "memory" {
#   description = "memory 크기 (단위: MB)"
#   type        = number
# }

variable "flavor_id" {
  description = "인스턴스에 사용할 flavor ID."
  type        = string
}