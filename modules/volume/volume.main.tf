terraform {
  # required_version = ">= 1.4.0"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

resource "openstack_blockstorage_volume_v3" "additional_disk" {
  count       = length(var.disk_sizes)
  name        = "${var.instance_name}-disk-${count.index + 1}"
  size        = var.disk_sizes[count.index] # Pass disk sizes via variable
  description = "Additional volume for ${var.instance_name}"
  # volume_type = var.volume_type
}
