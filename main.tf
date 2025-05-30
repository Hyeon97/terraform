module "instance" {
  source                      = "./modules/instance"
  network_name                = var.network_name
  subnet_name                 = var.subnet_name
  instance_name               = var.instance_name
  image_uuid                  = var.image_uuid
  flavor_id                   = var.flavor_id
  volume_size                 = var.volume_size
  volume_type                 = var.volume_type
  region                      = var.region
  cpu                         = var.cpu
  memory                      = var.memory
  security_group_names        = var.security_group_names
  create_new_security_groups  = var.create_new_security_groups
  allowed_ssh_cidr            = var.allowed_ssh_cidr
  create_default_sg_rules     = var.create_default_sg_rules
  user_data_file_path         = var.user_data_file_path
  additional_volumes          = var.additional_volumes
  external_network_name       = var.external_network_name
  project_id                  = local.project_id
  # Keypair 관련 변수 추가
  use_keypair                 = var.use_keypair
  keypair_name                = var.keypair_name
  public_key_path             = var.public_key_path
  create_new_keypair          = var.create_new_keypair
  providers = {
    openstack = openstack
  }
}