# Keypair 출력
output "flavor_info" {
  description = "flavor Info"
  value       = data.openstack_compute_flavor_v2.available_flavor
}

# Outputs:

# first_flavor = {
#   "description" = ""
#   "disk" = 0
#   "extra_specs" = tomap({})
#   "flavor_id" = "208d0f09-2cfe-4696-9afd-af7259522a71"
#   "id" = "208d0f09-2cfe-4696-9afd-af7259522a71"
#   "is_public" = true
#   "min_disk" = tonumber(null)
#   "min_ram" = tonumber(null)
#   "name" = "m1.tiny"
#   "ram" = 512
#   "region" = "RegionOne"
#   "rx_tx_factor" = 1
#   "swap" = 0
#   "vcpus" = 1
# }