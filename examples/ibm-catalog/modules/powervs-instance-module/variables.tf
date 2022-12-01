variable "prerequisite_workspace_id" {
  description = "IBM Cloud Schematics workspace ID of an existing PowerVS secure infrastructure."
  type        = string
}

variable "powervs_zone" {
  description = "IBM Cloud data center location where IBM PowerVS infrastructure will be created."
  type        = string
}

#####################################################
# Optional Parameters
#####################################################

variable "ibmcloud_api_key" {
  description = "IBM Cloud api key."
  type        = string
  sensitive   = true
}

variable "powervs_instance_name" {
  description = "PowerVS instance name"
  type        = string
  default     = "quickstart"
}

variable "server_type" {
  description = "Server type"
  type        = string
  default     = "s922"
}

variable "cpu_proc_type" {
  description = "CPU processor type"
  type        = string
  default     = "shared"
}

variable "number_of_processors" {
  description = "Number of CPU processor type"
  type        = string
  default     = "1"
}

variable "memory_size" {
  description = "Memory size"
  type        = string
  default     = "64"
}

variable "powervs_os_image_name" {
  description = "Image to be deployed"
  type        = string
  default     = "RHEL8-SP4-SAP-NETWEAVER"
}

variable "storage_config" {
  description = "Storage configuration for the instance"
  type = object({
    names      = string
    disks_size = string
    counts     = string
    tiers      = string
    paths      = string
  })
  default = {
    names      = "data"
    disks_size = "2000,2000"
    counts     = "2"
    tiers      = "tier3"
    paths      = "/data"
  }
}

#############################################################################
# Schematics Output
#############################################################################

# tflint-ignore: terraform_naming_convention
variable "IC_SCHEMATICS_WORKSPACE_ID" {
  default     = ""
  type        = string
  description = "leave blank if running locally. This variable will be automatically populated if running from an IBM Cloud Schematics workspace"
}
