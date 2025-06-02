# Keypair 출력 (통합)
output "keypair_name" {
  description = "사용된 Keypair의 이름"
  value = var.create_keypair ? (
    length(openstack_compute_keypair_v2.my_keypair) > 0 ? openstack_compute_keypair_v2.my_keypair[0].name : ""
  ) : (
    length(data.openstack_compute_keypair_v2.existing_keypair) > 0 ? data.openstack_compute_keypair_v2.existing_keypair[0].name : ""
  )
}

output "keypair_info" {
  description = "Keypair 상세 정보"
  value = var.create_keypair ? (
    length(openstack_compute_keypair_v2.my_keypair) > 0 ? {
      name        = openstack_compute_keypair_v2.my_keypair[0].name
      fingerprint = openstack_compute_keypair_v2.my_keypair[0].fingerprint
      source      = "created"
    } : null
  ) : (
    length(data.openstack_compute_keypair_v2.existing_keypair) > 0 ? {
      name        = data.openstack_compute_keypair_v2.existing_keypair[0].name
      fingerprint = data.openstack_compute_keypair_v2.existing_keypair[0].fingerprint
      source      = "existing"
    } : null
  )
}