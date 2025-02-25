
variable "address_space" {
  description = "The address space for the virtual network"
  default     = ["10.0.0.0/16"]

}

variable "vnet-name" {
  description = "The name of the vnet"
  default     = "tech501-yahya-2-subnet-vnet"

}

variable "app_source_image_id" {
  description = "The ID of the VM Image"

}

variable "db_source_image_id" {
  description = "The ID of the VM Image"

}

variable "rg_name" {
  description = "The name of the Resource Group"

}