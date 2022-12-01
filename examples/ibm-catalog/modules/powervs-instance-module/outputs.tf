output "instance_management_ip" {
  description = "IP of created PowerVS instance"
  value       = module.power_instance.instance_mgmt_ip
}

output "schematics_workspace_id" {
  description = "ID of the IBM Cloud Schematics workspace. Returns null if not ran in Schematics"
  value       = var.IC_SCHEMATICS_WORKSPACE_ID
}
