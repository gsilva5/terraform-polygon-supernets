locals {
  network_type       = "edge"
  base_ami           = "ami-0ecc74eca1d66d8a6"
  base_dn            = format("%s.%s.%s.private", var.deployment_name, local.network_type, var.company_name)
  base_id = format("%s-%s", var.deployment_name, local.network_type)
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.58.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.22.0"
    }
  }
  required_version = ">= 1.2.0"
}

module "dns" {
  source                       = "./modules/dns"
  base_dn                      = local.base_dn
  region                       = var.region
  fullnode_count               = var.fullnode_count
  validator_count              = var.validator_count

  devnet_id = "${module.networking.devnet_id}"
  aws_lb_domain = "${module.elb.aws_lb_domain}"
  validator_private_ips = module.ec2.validator_private_ips
  fullnode_private_ips = module.ec2.fullnode_private_ips
}

module "ebs" {
  source                       = "./modules/ebs"
  zones               = var.zones
  node_storage              = var.node_storage
  validator_count              = var.validator_count
  fullnode_count               = var.fullnode_count

  validator_instance_ids = module.ec2.validator_instance_ids
  fullnode_instance_ids = module.ec2.fullnode_instance_ids
}

module "ec2" {
  source                       = "./modules/ec2"
  base_dn = local.base_dn
  base_instance_type           = var.base_instance_type
  base_ami                     = local.base_ami
  fullnode_count               = var.fullnode_count
  validator_count              = var.validator_count
  jumpbox_count                = var.jumpbox_count
  base_devnet_key_name              = format("%s_ssh_key", var.deployment_name)
  private_network_mode = var.private_network_mode
  network_type                 = local.network_type
  deployment_name              = var.deployment_name
  create_ssh_key = var.create_ssh_key
  devnet_key_value = var.devnet_key_value
  jumpbox_instance_type = var.jumpbox_instance_type

  devnet_private_subnet_ids = module.networking.devnet_private_subnet_ids
  devnet_public_subnet_ids = module.networking.devnet_public_subnet_ids
  ec2_profile_name = module.ssm.ec2_profile_name
}

module "elb" {
  source                       = "./modules/elb"
  http_rpc_port                = var.http_rpc_port
  fullnode_count               = var.fullnode_count
  validator_count              = var.validator_count
  base_id = local.base_id

  devnet_private_subnet_ids = module.networking.devnet_private_subnet_ids
  devnet_public_subnet_ids = module.networking.devnet_public_subnet_ids
  fullnode_instance_ids = module.ec2.fullnode_instance_ids
  devnet_id = module.networking.devnet_id
  security_group_open_http_id = module.securitygroups.security_group_open_http_id
  security_group_default_id = module.securitygroups.security_group_default_id
}

module "networking" {
  source                       = "./modules/networking"
  base_dn                      = local.base_dn
  devnet_vpc_block = var.devnet_vpc_block
  devnet_public_subnet = var.devnet_public_subnet
  devnet_private_subnet = var.devnet_private_subnet
  zones = var.zones
}

module "securitygroups" {
  source                       = "./modules/securitygroups"
  depends_on = [
    module.networking
  ]
  jumpbox_count                = var.jumpbox_count
  network_type                 = local.network_type
  deployment_name              = var.deployment_name
  jumpbox_ssh_access = var.jumpbox_ssh_access
  network_acl = var.network_acl
  http_rpc_port = var.http_rpc_port

  devnet_id = module.networking.devnet_id
  validator_primary_network_interface_ids = module.ec2.validator_primary_network_interface_ids
  fullnode_primary_network_interface_ids = module.ec2.fullnode_primary_network_interface_ids
  jumpbox_primary_network_interface_ids = module.ec2.jumpbox_primary_network_interface_ids
}

module "ssm" {
  source                       = "./modules/ssm"
  base_dn                      = local.base_dn
  jumpbox_ssh_access = var.jumpbox_ssh_access
  deployment_name              = var.deployment_name
  network_type                 = local.network_type
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment    = var.environment
      Network        = local.network_type
      Owner          = var.owner
      DeploymentName = var.deployment_name
      BaseDN         = local.base_dn
      Name           = local.base_dn
    }
  }
}