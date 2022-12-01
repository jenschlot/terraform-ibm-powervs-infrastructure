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
  powerinfra_output = jsondecode(data.ibm_schematics_output.schematics_output.output_json)

  powervs_resource_group_name = local.powerinfra_output[0].powervs_resource_group_name.value
  powervs_workspace_name      = local.powerinfra_output[0].powervs_workspace_name.value
  powervs_sshkey_name         = local.powerinfra_output[0].powervs_sshkey_name.value
  management_network_name     = local.powerinfra_output[0].powervs_management_network_name.value
  backup_network_name         = local.powerinfra_output[0].powervs_backup_network_name.value
}

module "power_instance" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-powervs-sap.git//submodules/power_instance?ref=v3.1.0"
  powervs_zone                 = var.powervs_zone
  powervs_resource_group_name  = local.powervs_resource_group_name
  powervs_workspace_name       = local.powervs_workspace_name
  powervs_instance_name        = var.powervs_instance_name
  powervs_sshkey_name          = local.powervs_sshkey_name
  powervs_os_image_name        = var.powervs_os_image_name
  powervs_server_type          = var.server_type
  powervs_cpu_proc_type        = var.cpu_proc_type
  powervs_number_of_processors = var.number_of_processors
  powervs_memory_size          = var.memory_size
  powervs_networks             = [local.management_network_name, local.backup_network_name]
  powervs_storage_config       = var.storage_config
}
