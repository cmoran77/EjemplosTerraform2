# Terraform script to learn differents topics about Azure's vnets
# Author: Carlos Moran

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "Network-Learning"
  location = "eastus2"

  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# Create a public ip
resource "azurerm_public_ip" "public_ip_vm1" {
  name                = "public_ip_vm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg-learning" {
  name                = "nsg-learning"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # NSG custom rules
  security_rule {
    name                       = "allow-ssh"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-HTTP"
    priority                   = 600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# Create the Vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-learning"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# Create subnet 1 in vnet
resource "azurerm_subnet" "subnet1" {
  name           = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = ["10.0.1.0/24"]
}

#Create subnet 2 in vnet
resource "azurerm_subnet" "subnet2" {
  name           = "subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = ["10.0.2.0/24"]
}

# --------------------------------------------------------------
# Create the Vnet 2
resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet-learning2"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# Create subnet 1 in vnet 2
resource "azurerm_subnet" "subnet1-vnet2" {
  name           = "subnet1_vnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes       = ["10.1.0.0/24"]
}

# Association of NSG with Subnet1
resource "azurerm_subnet_network_security_group_association" "nsga" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg-learning.id
}

# =================================================================================================
# Definition of Virtual Machines

# Create a Network Interface for VM1
resource "azurerm_network_interface" "nic1" {
  name                = "vm1_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ip_vm1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.5"
    public_ip_address_id          = azurerm_public_ip.public_ip_vm1.id
  }

  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# Create the Virtual Machine 1 in the vnet vnet-learning
resource "azurerm_virtual_machine" "vm" {
  name                  = "vm1_network_learning"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  vm_size               = "Standard_B1ms"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  
  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# ---------------------------------------------------------------------

# Create a Network Interface for VM2 in Vnet 2
resource "azurerm_network_interface" "nic2" {
  name                = "vm2_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ip_vm2"
    subnet_id                     = azurerm_subnet.subnet1-vnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.0.5"
  }

  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# Create the Virtual Machine 2 in the vnet vnet-learning2
resource "azurerm_virtual_machine" "vm2" {
  name                  = "vm2_network_learning"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  vm_size               = "Standard_B1ms"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk2_vm2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Environment = "DEV"
    Team = "Learning"
  }
}

# Association of NSG with subnet1-vnet2
resource "azurerm_subnet_network_security_group_association" "nsga2" {
  subnet_id                 = azurerm_subnet.subnet1-vnet2.id
  network_security_group_id = azurerm_network_security_group.nsg-learning.id
}

# Create peering within 
resource "azurerm_virtual_network_peering" "peering_vnet1_to_vnet2" {
  name                      = "peering_vnet1_to_vnet2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "peering_vnet2_to_vnet1" {
  name                      = "peering_vnet2_to_vnet1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

