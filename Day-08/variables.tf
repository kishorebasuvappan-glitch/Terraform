variable "resource_group_name" {
    description = "name of the rg"
    type =string
}

variable "location" {
    description = "azure region"
    type = string
}

variable "virtual_network_name" {
    description = "name of the vnet"
    type =string
}

variable "subnet_name"{
    description = "name of the subnet"
    type = string
}