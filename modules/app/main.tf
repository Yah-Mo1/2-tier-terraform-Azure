#APP VM
variable "app_prefix" {
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


resource "azurerm_network_security_group" "nsg" {
  name                = "${var.app_prefix}-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

}
# Inbound SSH Rule (Port 22)
resource "azurerm_network_security_rule" "ssh_rule" {
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
  network_security_group_name = azurerm_network_security_group.nsg.name
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
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "db_mongodb_rule" {
    resource_group_name = "tech501"
  name                        = "Allow-MongoDB"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "27017"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_interface_security_group_association" "nsg-association" {
  network_interface_id      = azurerm_network_interface.app-NIC.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


data "azurerm_ssh_public_key" "tech-501-yahya-az-key" {
  name                = "tech-501-yahya-az-key"
  resource_group_name = "tech501"
}



//TODO: Issue i am facing is that the post page doesnt show all the posts (internal server 500 error). Investigate this!!!!
//TODO2: https://chatgpt.com/c/67bc9620-c04c-800d-8ad4-1327cb921489 TODO2: Look into this
resource "azurerm_linux_virtual_machine" "tech501-yahya-terraform-app-vm" {
  name                  = "${var.app_prefix}-app-vm"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.app-NIC.id]

  admin_ssh_key {
    username   = "azureuser"
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

custom_data = base64encode(<<EOF
#!/bin/bash
# Install and configure application dependencies

# Update system packages
sudo apt update && sudo apt upgrade -y

# # Install Nginx
# sudo apt install nginx -y
# sudo systemctl enable nginx
# sudo systemctl start nginx

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
# export DB_HOST=mongodb://${var.privateIP}:27017/posts
# Install application dependencies and seed the database
cd /test-app
sudo npm install

# Start the application with PM2
pm2 start app.js
EOF
  )

  tags = {
    owner = "yahya"
  }


# depends_on = [ azurerm_linux_virtual_machine.tech501-yahya-terraform-db-vm ]
}
