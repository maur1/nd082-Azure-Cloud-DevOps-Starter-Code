variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "UC1"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "East US"
}

variable "num_of_vms" {
  description = "Amount of VMs to be deployed"
  default = "2"
}

variable "username" {
  description = "Default username for admin user, stored as env variable"
  sensitive = true
}

variable "password" {
  description = "Default pwd for admin user, stored as env variable"
  sensitive = true
}

