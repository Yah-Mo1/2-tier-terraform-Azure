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
data "azurerm_subnet" "private_subnet" {
  name                 = "private-subnet"
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

resource "azurerm_network_security_group" "db-nsg" {
  name                = "${var.db_prefix}-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

}
# Inbound SSH Rule (Port 22)
resource "azurerm_network_security_rule" "db_ssh_rule" {
  resource_group_name         = "tech501"
  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.db-nsg.name
}


resource "azurerm_network_interface_security_group_association" "db-nsg-association" {
  network_interface_id      = azurerm_network_interface.db-Nic.id
  network_security_group_id = azurerm_network_security_group.db-nsg.id
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
    public_key = file("~/.sshkey/tech501-yahya-az-key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

    source_image_id = var.db_source_image_id

  tags = {
    owner = "yahya"
  }

}




# APP VM
variable "app_prefix" {
  default = "2-tier"
}

data "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "app-NIC" {
  name                = "${var.app_prefix}-app-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "app-NIC-Ip"
    subnet_id                     = data.azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tech501-yahya-sparta-public-ip.id

  }
}
resource "azurerm_public_ip" "tech501-yahya-sparta-public-ip" {
  name                = "${var.app_prefix}-public-ip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic" # or "Static" if you require a fixed IP
  sku                 = "Basic"   # or "Standard" depending on your needs
}


resource "azurerm_network_security_group" "app-nsg" {
  name                = "${var.app_prefix}-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

}
# Inbound SSH Rule (Port 22)
resource "azurerm_network_security_rule" "ssh_rule" {
  resource_group_name         = "tech501"
  name                        = "app-Allow-SSH"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.app-nsg.name
}


# Inbound HTTP Rule (Port 80)
resource "azurerm_network_security_rule" "http_rule" {
  resource_group_name         = "tech501"
  name                        = "Allow-HTTP"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.app-nsg.name
}

resource "azurerm_network_interface_security_group_association" "nsg-association" {
  network_interface_id      = azurerm_network_interface.app-NIC.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id
}


data "azurerm_ssh_public_key" "tech-501-yahya-az-key" {
  name                = "tech-501-yahya-az-key"
  resource_group_name = "tech501"
}




resource "azurerm_linux_virtual_machine" "tech501-yahya-terraform-app-vm" {
  name                  = "${var.app_prefix}-app-vm"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.app-NIC.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.sshkey/tech501-yahya-az-key.pub")
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

  custom_data = base64encode(<<EOF
#!/bin/bash
# Install and configure application dependencies

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs

# Install PM2 process manager
sudo npm install -g pm2

# Clone the application repository
git clone https://github.com/Yah-Mo1/test-app

# Configure Nginx as a reverse proxy
sudo sed -i 's|try_files.*|proxy_pass http://127.0.0.1:3000;|' /etc/nginx/sites-available/default
sudo systemctl reload nginx

# Set up database connection
 export DB_HOST=mongodb://${azurerm_network_interface.db-Nic.private_ip_address}:27017/posts

# Install application dependencies and seed the database
cd test-app
npm install

# Start the application with PM2
pm2 start app.js
EOF
  )

  tags = {
    owner = "yahya"
  }


  depends_on = [azurerm_linux_virtual_machine.tech501-yahya-terraform-db-vm]
}
