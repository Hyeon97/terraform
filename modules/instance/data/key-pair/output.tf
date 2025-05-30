# Keypair 출력
output "keypair_name" {
  description = "생성된 Keypair의 이름"
  value       = openstack_compute_keypair_v2.my_keypair.name
}
