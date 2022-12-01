output "powervs_workspace_name" {
  description = "PowerVS infrastructure workspace name."
  value       = module.powervs_infra.powervs_workspace_name
}

output "powervs_sshkey_name" {
  description = "SSH public key name in created PowerVS infrastructure."
  value       = module.powervs_infra.powervs_sshkey_name
}

output "powervs_zone" {
  description = "Zone where PowerVS infrastructure is created."
  value       = module.powervs_infra.powervs_zone
}

output "powervs_resource_group_name" {
  description = "IBM Cloud resource group where PowerVS infrastructure is created."
  value       = module.powervs_infra.powervs_resource_group_name
}

output "cloud_connection_count" {
  description = "Number of cloud connections configured in created PowerVS infrastructure."
  value       = module.powervs_infra.cloud_connection_count
}

output "powervs_management_network_name" {
  description = "Name of management network in created PowerVS infrastructure."
  value       = module.powervs_infra.powervs_management_network_name
}

output "powervs_backup_network_name" {
  description = "Name of backup network in created PowerVS infrastructure."
  value       = module.powervs_infra.powervs_backup_network_name
}

output "access_host_or_ip" {
  description = "Access host for created PowerVS infrastructure."
  value       = module.powervs_infra.access_host_or_ip
}

output "proxy_host_or_ip_port" {
  description = "Proxy host:port for created PowerVS infrastructure."
  value       = module.powervs_infra.proxy_host_or_ip_port
}

output "dns_host_or_ip" {
  description = "DNS forwarder host for created PowerVS infrastructure."
  value       = module.powervs_infra.dns_host_or_ip
}

output "ntp_host_or_ip" {
  description = "NTP host for created PowerVS infrastructure."
  value       = module.powervs_infra.ntp_host_or_ip
}

output "nfs_path" {
  description = "NFS host for created PowerVS infrastructure."
  value       = module.powervs_infra.nfs_path
}

output "schematics_workspace_id" {
  description = "ID of the IBM Cloud Schematics workspace. Returns null if not ran in Schematics"
  value       = var.IC_SCHEMATICS_WORKSPACE_ID
}

output "connection_command" {
  description = "1. Connect to ReadyImage using following command. Note: If you use a non-default path to your SSH key, you must specify it over following SSH client parameter: '-i <path_to_your_SSH_private_key>'."
  value       = "ssh -A -o ServerAliveInterval=60 -o ServerAliveCountMax=600 -o ProxyCommand=\"ssh -W %h:%p root@${module.powervs_infra.access_host_or_ip}\" root@${module.power_instance.instance_mgmt_ip}"
}

output "proxy_config" {
  description = "2. Configure proxy to reach public internet."
  value       = "export http_proxy=http://${module.powervs_infra.proxy_host_or_ip_port}:3128; export https_proxy= http://${module.powervs_infra.proxy_host_or_ip_port}:3128; export HTTP_proxy= http://${module.powervs_infra.proxy_host_or_ip_port}:3128;export HTTPS_proxy =http://${module.powervs_infra.proxy_host_or_ip_port}:3128"
}

output "success_message" {
  description = "Enjoy"
  value       = "Enjoy! :-)"
}
