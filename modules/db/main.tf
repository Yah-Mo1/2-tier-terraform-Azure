# DB VM
variable "db_prefix" {
  default = "2-tier"
}
data "azurerm_resource_group" "rg" {
  name = var.rg_name

}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet-name
  resource_group_name = data.azurerm_resource_group.rg.name
}
data "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "db-Nic" {
  name                = "${var.db_prefix}-db-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "db-NIC-Ip"
    subnet_id                     = data.azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

data "azurerm_ssh_public_key" "ssh-key" {
  name                = "tech-501-yahya-az-key"
  resource_group_name = "tech501"
}

# data "azurerm_image" "tech501-yahya-sparta-db-img" {
#   name                = "tech501-ramon-sparta-app-ready-to-run-db"
#   resource_group_name = data.azurerm_resource_group.rg.name
# }

resource "azurerm_linux_virtual_machine" "tech501-yahya-terraform-db-vm" {
  name                  = "${var.db_prefix}-db-vm"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.db-Nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/Users/yahmoham1/.sshkey/tech501-yahya-az-key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # This line encodes your user data script in Base64
#   custom_data = filebase64("../../scripts/db.sh")
  custom_data = filebase64("${path.module}/../../scripts/db.sh")


  tags = {
    owner = "yahya"
  }
}


