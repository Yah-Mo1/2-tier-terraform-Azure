variable "address_space" {
  description = "The address space for the virtual network"
  default     = ["10.0.0.0/16"]

}

variable "vnet-name" {
  description = "The name of the vnet"
}


variable "rg_name" {
  description = "The name of the Resource Group"

}

variable "privateIP" {
    description = "The private IP of the Database virtual machine"
  
}