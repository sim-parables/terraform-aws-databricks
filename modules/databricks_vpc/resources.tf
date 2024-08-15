/* Databricks AWS VPC Depoloyment and Configuraiton */

terraform{
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.accounts, ]
    }
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.auth_session, ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS AVAILABILITY ZONES DATA SOURCE
##
## This data source retrieves information about the available AWS Availability Zones.
##
## Providers:
## - `aws.auth_session`: The AWS Authenticated Session provider.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  provider = aws.auth_session
}

## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  cloud   = "aws"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  prefix    = "${local.program}-${local.project}-${random_string.this.id}"
  vpc_name = var.aws_vpc_name != null ? var.aws_vpc_name : "${local.prefix}-databricks-workspace"
  tags      = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## VPC MODULE
##
## The VPC module creates a VPC with public and private subnets across multiple availability zones (AZs) in an AWS Region.
## It also configures NAT gateways, Internet gateways, route tables, and security groups.
##
## Parameters:
## - `name`: The name of the VPC.
## - `cidr`: The CIDR block for the VPC.
## - `azs`: The list of availability zones in which to create subnets.
## - `tags`: A map of tags to apply to all resources created by this module.
## - `enable_dns_hostnames`: Whether to enable DNS hostnames in the VPC.
## - `enable_nat_gateway`: Whether to create NAT gateways for the private subnets.
## - `single_nat_gateway`: Whether to use a single NAT gateway for all private subnets.
## - `create_igw`: Whether to create an Internet gateway for the VPC.
## - `public_subnets`: List of CIDR blocks for the public subnets.
## - `private_subnets`: List of CIDR blocks for the private subnets.
## - `manage_default_security_group`: Whether to manage the default security group.
## - `default_security_group_name`: The name of the default security group.
## - `default_security_group_egress`: Egress rules for the default security group.
## - `default_security_group_ingress`: Ingress rules for the default security group.
##
## Providers:
## - `aws`: The AWS provider.
## ---------------------------------------------------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.12.1"

  name = local.vpc_name
  cidr = var.cidr_block
  azs  = data.aws_availability_zones.available.names
  tags = local.tags

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  create_igw           = true

  public_subnets = [cidrsubnet(var.cidr_block, 3, 0)]
  private_subnets = [
    cidrsubnet(var.cidr_block, 3, 1),
    cidrsubnet(var.cidr_block, 3, 2)
  ]

  manage_default_security_group = true
  default_security_group_name   = "${local.vpc_name}-sg"

  default_security_group_egress = [{
    cidr_blocks = "0.0.0.0/0"
  }]

  default_security_group_ingress = [{
    description = "Allow all internal TCP and UDP"
    self        = true
  }]

  providers = {
    aws = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## VPC ENDPOINTS MODULE
##
## The VPC endpoints module creates endpoints for specific AWS services within the VPC, enabling private connectivity
## to these services without the need for public IPs or internet gateways.
##
## Parameters:
## - `vpc_id`: The ID of the VPC in which to create the endpoints.
## - `security_group_ids`: List of security group IDs to associate with the endpoints.
## - `endpoints`: A map of endpoint configurations, each specifying the service, service type, route table IDs (for Gateway
##   endpoints), subnet IDs, and tags.
## - `tags`: A map of tags to apply to all resources created by this module.
##
## Providers:
## - `aws`: The AWS provider.
## ---------------------------------------------------------------------------------------------------------------------
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.12.1"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]

  endpoints = {
    s3 = {
      service        = "s3"
      service_type   = "Gateway"
      route_table_ids = flatten([
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids
      ])
      tags = merge(local.tags, {
        Name = "${local.vpc_name}-s3-vpc-endpoint"
      })
    },
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = merge(local.tags, {
        Name = "${local.vpc_name}-sts-vpc-endpoint"
      })
    },
    kinesis-streams = {
      service             = "kinesis-streams"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags = merge(local.tags, {
        Name = "${local.vpc_name}-kinesis-vpc-endpoint"
      })
    },
  }

  tags = local.tags

  providers = {
    aws = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS NETWORKS RESOURCE
##
## The Databricks MWS Networks resource creates a network configuration for Databricks, associating it with a VPC, 
## specifying the security group IDs and subnet IDs to use.
##
## Parameters:
## - `account_id`: The ID of the Databricks account.
## - `network_name`: The name of the network configuration.
## - `security_group_ids`: List of security group IDs to associate with the network.
## - `subnet_ids`: List of subnet IDs for the network.
## - `vpc_id`: The ID of the VPC in which the network is located.
##
## Providers:
## - `databricks`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_networks" "this" {
  provider           = databricks.accounts
  account_id         = var.databricks_account_id
  network_name       = "${local.vpc_name}-network"
  security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id
}
