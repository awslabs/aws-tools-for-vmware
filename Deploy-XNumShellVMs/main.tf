provider "vsphere" {
  version = "~> 1.13"

  vsphere_server       = "${var.vsphere_server}"
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"

  # Do not permit self-signed certificates
  allow_unverified_ssl = false
}

locals {
  folder_name = "${var.num_shell_vms} Shell VMs... GO!"
}

data "vsphere_datacenter" "dc" {
  name = "SDDC-Datacenter"
}

data "vsphere_resource_pool" "pool" {
  name          = "Compute-ResourcePool"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "datastore" {
  name          = "WorkloadDatastore"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "${var.network}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_folder" "folder" {
  path          = "Workloads/${local.folder_name}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  count = "${var.num_shell_vms}"

  name     = "ShellVM-${count.index}"
  guest_id = "other3xLinux64Guest"

  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "Workloads/${local.folder_name}"

  num_cpus = 1
  memory   = 4

  wait_for_guest_net_timeout = 0
  wait_for_guest_net_routable = false
  shutdown_wait_timeout = 1

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label = "disk0"
    size  = 1
  }

  depends_on = ["vsphere_folder.folder"]
}
