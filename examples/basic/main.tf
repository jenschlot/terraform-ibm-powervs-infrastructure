locals {
  ibm_powervs_zone_region_map = {
    "syd04"    = "syd"
    "syd05"    = "syd"
    "eu-de-1"  = "eu-de"
    "eu-de-2"  = "eu-de"
    "lon04"    = "lon"
    "lon06"    = "lon"
    "tok04"    = "tok"
    "us-east"  = "us-east"
    "us-south" = "us-south"
    "dal12"    = "us-south"
    "tor01"    = "tor"
    "osa21"    = "osa"
    "sao01"    = "sao"
    "mon01"    = "mon"
    "wdc06"    = "us-east"
  }

  ibm_powervs_zone_cloud_region_map = {
    "syd04"    = "au-syd"
    "syd05"    = "au-syd"
    "eu-de-1"  = "eu-de"
    "eu-de-2"  = "eu-de"
    "lon04"    = "eu-gb"
    "lon06"    = "eu-gb"
    "tok04"    = "jp-tok"
    "us-east"  = "us-east"
    "us-south" = "us-south"
    "dal12"    = "us-south"
    "tor01"    = "ca-tor"
    "osa21"    = "jp-osa"
    "sao01"    = "br-sao"
    "mon01"    = "ca-tor"
    "wdc06"    = "us-east"
  }

  # Condition to determine if example needs to provision a transit gateway
  provision_transit_gateway = ((var.transit_gateway_name == null) && (!var.reuse_cloud_connections))
}

# There are discrepancies between the region inputs on the powervs terraform resource, and the vpc ("is") resources
provider "ibm" {
  alias            = "ibm-pvs"
  region           = lookup(local.ibm_powervs_zone_region_map, var.powervs_zone, null)
  zone             = var.powervs_zone
  ibmcloud_api_key = var.ibmcloud_api_key
}

provider "ibm" {
  alias            = "ibm-is"
  region           = lookup(local.ibm_powervs_zone_cloud_region_map, var.powervs_zone, null)
  zone             = var.powervs_zone
  ibmcloud_api_key = var.ibmcloud_api_key
}

# Security Notice
# The private key generated by this resource will be stored unencrypted in your Terraform state file.
# Use of this resource for production deployments is not recommended.
# Instead, generate a private key file outside of Terraform and distribute it securely to the system where
# Terraform will be run.

resource "tls_private_key" "tls_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "ssh_key" {
  provider   = ibm.ibm-is
  name       = "${var.prefix}-${var.powervs_sshkey_name}"
  public_key = trimspace(tls_private_key.tls_key.public_key_openssh)
}

########################################################################################################################
# Account Resource Group
########################################################################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# Create Transit Gateway if needed
# IF transit_gateway_name = null AND reuse_cloud_connections = false
# THEN provision new transit gateway in region of powervs zone
########################################################################################################################
resource "ibm_tg_gateway" "powervs_gateway" {
  count          = local.provision_transit_gateway ? 1 : 0
  provider       = ibm.ibm-is
  name           = "${var.prefix}-${var.powervs_workspace_name}-tgw"
  location       = lookup(local.ibm_powervs_zone_cloud_region_map, var.powervs_zone, null)
  global         = true
  resource_group = module.resource_group.resource_group_id
}

########################################################################################################################
# Instantiate PowerVS infrastructure
########################################################################################################################

module "powervs_infra" {
  # Some explicit depends_on required here:
  # module.resource_group required due to https://github.com/terraform-ibm-modules/terraform-ibm-powervs-infrastructure/issues/143
  # ibm_tg_gateway.powervs_gateway required likely due to different provider alias used in this example
  depends_on = [
    module.resource_group,
    ibm_tg_gateway.powervs_gateway
  ]

  providers = {
    ibm = ibm.ibm-pvs
  }

  source = "../../"

  powervs_zone                 = var.powervs_zone
  powervs_resource_group_name  = module.resource_group.resource_group_name
  powervs_workspace_name       = "${var.prefix}-${var.powervs_zone}-${var.powervs_workspace_name}"
  tags                         = var.resource_tags
  powervs_image_names          = var.powervs_image_names
  powervs_sshkey_name          = "${var.prefix}-${var.powervs_zone}-${var.powervs_sshkey_name}"
  ssh_public_key               = ibm_is_ssh_key.ssh_key.public_key
  ssh_private_key              = trimspace(tls_private_key.tls_key.private_key_openssh)
  access_host_or_ip            = var.access_host_or_ip
  powervs_management_network   = var.powervs_management_network
  powervs_backup_network       = var.powervs_backup_network
  transit_gateway_name         = local.provision_transit_gateway ? ibm_tg_gateway.powervs_gateway[0].name : var.transit_gateway_name
  reuse_cloud_connections      = var.reuse_cloud_connections
  cloud_connection_name_prefix = var.prefix
  cloud_connection_count       = var.cloud_connection_count
  cloud_connection_speed       = var.cloud_connection_speed
  cloud_connection_gr          = var.cloud_connection_gr
  cloud_connection_metered     = var.cloud_connection_metered
  squid_config                 = var.squid_config
  dns_forwarder_config         = var.dns_forwarder_config
  ntp_forwarder_config         = var.ntp_forwarder_config
  nfs_config                   = var.nfs_config
  perform_proxy_client_setup   = var.perform_proxy_client_setup
}
