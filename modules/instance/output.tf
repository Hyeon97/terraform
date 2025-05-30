# output "instance_info" {
#   value     = openstack_compute_instance_v2.instance
#   sensitive = false  # Force Terraform to display everything
# }

output "instance_info" {
  value = {
    id           = openstack_compute_instance_v2.instance.id
    name         = openstack_compute_instance_v2.instance.name
    access_ip_v4 = openstack_compute_instance_v2.instance.access_ip_v4
    access_ip_v6 = openstack_compute_instance_v2.instance.access_ip_v6
    flavor_name  = openstack_compute_instance_v2.instance.flavor_name
    region            = openstack_compute_instance_v2.instance.region
    key_pair          = openstack_compute_instance_v2.instance.key_pair
    security_groups   = openstack_compute_instance_v2.instance.security_groups
    availability_zone = openstack_compute_instance_v2.instance.availability_zone
    created_at        = openstack_compute_instance_v2.instance.created
    updated_at        = openstack_compute_instance_v2.instance.updated
    power_state       = openstack_compute_instance_v2.instance.power_state
    image_id          = openstack_compute_instance_v2.instance.image_id
    metadata          = openstack_compute_instance_v2.instance.metadata
    user_data         = openstack_compute_instance_v2.instance.user_data
  }
  sensitive = false # Ensure output is not treated as sensitive
}