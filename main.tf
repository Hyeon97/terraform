
module "instance" {
  source               = "./modules/instance"
  network_name         = var.network_name
  subnet_name          = var.subnet_name
  instance_name        = var.instance_name
  image_uuid           = var.image_uuid
  flavor_id            = var.flavor_id
  volume_size          = var.volume_size
  region               = var.region
  cpu                  = var.cpu
  memory               = var.memory
  security_group_names = var.security_group_names
  user_data_file_path  = var.user_data_file_path
  additional_volumes   = var.additional_volumes
  providers = {
    openstack = openstack
  }
}