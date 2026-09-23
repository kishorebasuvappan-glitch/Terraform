variable "resource_group_name" {
    description = "Name of the RG"
    type = set(string)
}

variable "location" {
    description = "azure location"
    type = string
}