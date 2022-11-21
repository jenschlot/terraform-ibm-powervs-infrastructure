locals {
  ibm_powervs_zone_region_map = {
    "syd04"    = "syd"
    "syd05"    = "syd"
    "eu-de-1"  = "eu-de"
    "eu-de-2"  = "eu-de"
    "lon04"    = "lon"
    "lon06"    = "lon"
    "wdc04"    = "us-east"
    "us-east"  = "us-east"
    "us-south" = "us-south"
    "dal12"    = "us-south"
    "dal13"    = "us-south"
    "tor01"    = "tor"
    "tok04"    = "tok"
    "osa21"    = "osa"
    "sao01"    = "sao"
    "mon01"    = "mon"

  }
}

provider "ibm" {
  region           = lookup(local.ibm_powervs_zone_region_map, var.powervs_zone, null)
  zone             = var.powervs_zone
  ibmcloud_api_key = var.ibmcloud_api_key != null ? var.ibmcloud_api_key : null
}

locals {
  location = regex("^[a-z/-]+", var.prerequisite_workspace_id)
}

data "ibm_schematics_workspace" "schematics_workspace" {
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
}

data "ibm_schematics_output" "schematics_output" {
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
  template_id  = data.ibm_schematics_workspace.schematics_workspace.runtime_data[0].id
}

locals {
  slz_output = jsondecode(data.ibm_schematics_output.schematics_output.output_json)

  inet_svs_ip    = [for vsi in local.slz_output[0].vsi_list.value : vsi.ipv4_address if vsi.name == "${local.slz_output[0].prefix.value}-inet-svs-1"][0]
  private_svs_ip = [for vsi in local.slz_output[0].vsi_list.value : vsi.ipv4_address if vsi.name == "${local.slz_output[0].prefix.value}-private-svs-1"][0]
  squid_port     = "3128"
}

locals {
  squid_config = {
    "squid_enable"      = "true"
    "server_host_or_ip" = local.inet_svs_ip
    "squid_port"        = local.squid_port
  }

  dns_config = {
    "dns_enable"        = "true"
    "dns_servers"       = "161.26.0.7; 161.26.0.8; 9.9.9.9;"
    "server_host_or_ip" = local.private_svs_ip
  }

  ntp_config = {
    "ntp_enable"        = "true"
    "server_host_or_ip" = local.private_svs_ip
  }

  nfs_config = {
    "nfs_enable"        = "true"
    "nfs_directory"     = "/nfs"
    "server_host_or_ip" = local.private_svs_ip
  }

  host_ips         = [local.dns_config["server_host_or_ip"], local.ntp_config["server_host_or_ip"], local.nfs_config["server_host_or_ip"]]
  squid_client_ips = distinct([for host_ip in local.host_ips : host_ip if host_ip != local.squid_config["server_host_or_ip"]])

  perform_proxy_client_setup = {
    squid_client_ips = local.squid_client_ips
    squid_server_ip  = local.squid_config["server_host_or_ip"]
    squid_port       = local.squid_config["squid_port"]
    no_proxy_env     = "161.0.0.0/8"
  }

  storage_config = {
    names      = "data"
    disks_size = "2000,2000"
    counts     = "2"
    tiers      = "tier3"
    paths      = "/data"
  }
}

module "powervs_infra" {
  source = "../../.."

  powervs_zone                = var.powervs_zone
  powervs_resource_group_name = "Default"
  powervs_workspace_name      = "${local.slz_output[0].prefix.value}-${var.powervs_zone}-power-workspace"
  tags                        = ["PowerVS", "readyImage", "quickstart"]
  powervs_image_names         = var.powervs_image_names
  powervs_sshkey_name         = "${local.slz_output[0].prefix.value}-${var.powervs_zone}-ssh-pvs-key"
  ssh_public_key              = local.slz_output[0].ssh_public_key.value
  ssh_private_key             = var.ssh_private_key
  powervs_management_network  = var.powervs_management_network
  powervs_backup_network      = var.powervs_backup_network
  transit_gateway_name        = local.slz_output[0].transit_gateway_name.value
  reuse_cloud_connections     = false
  cloud_connection_count      = 2
  cloud_connection_speed      = 5000
  cloud_connection_gr         = true
  cloud_connection_metered    = false
  access_host_or_ip           = local.slz_output[0].fip_vsi.value[0].floating_ip
  squid_config                = local.squid_config
  dns_forwarder_config        = local.dns_config
  ntp_forwarder_config        = local.ntp_config
  nfs_config                  = local.nfs_config
  perform_proxy_client_setup  = local.perform_proxy_client_setup
}

module "power_instance" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-powervs-sap.git//submodules/power_instance?ref=v3.1.0"
  depends_on                   = [module.powervs_infra]
  powervs_zone                 = var.powervs_zone
  powervs_resource_group_name  = "Default"
  powervs_workspace_name       = "${local.slz_output[0].prefix.value}-${var.powervs_zone}-power-workspace"
  powervs_instance_name        = "readyImage"
  powervs_sshkey_name          = "${local.slz_output[0].prefix.value}-${var.powervs_zone}-ssh-pvs-key"
  powervs_os_image_name        = var.ready_image_name
  powervs_server_type          = "s922"
  powervs_cpu_proc_type        = "shared"
  powervs_number_of_processors = "1"
  powervs_memory_size          = "64"
  powervs_networks             = [var.powervs_management_network["name"], var.powervs_backup_network["name"]]
  powervs_storage_config       = local.storage_config
}
