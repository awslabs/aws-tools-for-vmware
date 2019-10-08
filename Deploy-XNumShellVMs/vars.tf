variable "vsphere_server" {
  description = "Specifies the IP address or the DNS name of the vSphere server to which you want to connect."
}

variable "vsphere_user" {
  description = "Specifies the user name you want to use for authenticating with the server."
}

variable "vsphere_password" {
  description = "Specifies the password you want to use for authenticating with the server."
}

variable "num_shell_vms" {
  description = "The number of shell VMs to provision."
  default     = 10
}

variable "network" {
  description = "Specifies the logical network for the virtual machines."
  default     = "sddc-cgw-network-1"
}
