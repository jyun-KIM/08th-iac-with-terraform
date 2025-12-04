module "network" {
  source = "../../modules/terraform-aws-network"

  vpc_cidr = "10.0.0.0/16"
  azs      = ["ap-northeast-2a", "ap-northeast-2c"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

  project = local.project
  tags    = local.tags
}

module "compute" {
  source = "../../modules/terraform-aws-compute"

  vpc_id = module.network.vpc_id

  public_subnet_id  = module.network.public_subnet_ids
  private_subnet_id = module.network.private_subnet_ids

  root_volume_size = 30
  root_volume_type = "gp3"

  web_root_volume_size = 30
  web_root_volume_type = "gp3"

  project = local.project
  tags    = local.tags
}

module "elb" {
  source = "../../modules/terraform-aws-elb"

  vpc_id = module.network.vpc_id

  tg_ec2_ip         = module.compute.web_instance_ip
  public_subnet_ids = module.network.public_subnet_ids

  project = local.project
  tags    = local.tags
}