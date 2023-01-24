output "server_type" {
  description = "Server type"
  value       = module.power_instance.instance_mgmt_ip
}

output "cpu_proc_type" {
  description = "CPU processor type"
  value       = module.power_instance.instance_mgmt_ip
}

output "number_of_processors" {
  description = "Number of CPU processors"
  value       = module.power_instance.instance_mgmt_ip
}

output "memory_size" {
  description = "Memory size"
  value       = module.power_instance.instance_mgmt_ip
}

output "powervs_os_image_name" {
  description = "Image to be deployed"
  value       = module.power_instance.instance_mgmt_ip
}

output "storage_config" {
  description = "Storage configuration for the instance"
  value       = module.power_instance.instance_mgmt_ip
}

output "schematics_workspace_id" {
  description = "ID of the IBM Cloud Schematics workspace. Returns null if not ran in Schematics"
  value       = var.IC_SCHEMATICS_WORKSPACE_ID
}
