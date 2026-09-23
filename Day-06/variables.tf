variable "resource_groups" {
    description = "Name of the RG"
      type = map(object({
    location = string
    resource_group_name    = map(string)
  }))
}
