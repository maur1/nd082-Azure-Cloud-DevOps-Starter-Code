provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    Envirnoment = "C1 - Infrastructure"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

#Create an public ip
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-publicIP"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    Envirnoment = "C1 - Infrastructure"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-sg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AccessBetweenVMs"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = azurerm_subnet.internal.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }
    security_rule {
    name                       = "DenyAccessFromInternet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }
  tags = {
    Envirnoment = "C1 - Infrastructure"
  }
}

#Create a network interface
resource "azurerm_network_interface" "main" {
  count               = var.num_of_vms
  name                = "${var.prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Envirnoment = "C1 - Infrastructure"
  }
}



#Create a load balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-loadBalancer"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-publicIP"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  
  tags = {
    Envirnoment = "C1 - Infrastructure"
  }
}

#Create azure lb probe
resource "azurerm_lb_probe" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-lbProbe"
  port                = 80
}

#Create backend address pool for load balancer
resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-backendAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.num_of_vms
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-vmAvailabilitySet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2

  tags = {
    Envirnoment = "C1 - Infrastructure"
  }
}

data "azurerm_image" "image" {
  name                = "Ubuntu18Image"
  resource_group_name = "packer-rg"
}

resource "azurerm_virtual_machine" "main" {
    count                 = var.num_of_vms
    name                  = "${var.prefix}-vm${count.index}"
    resource_group_name   = azurerm_resource_group.main.name
    location              = azurerm_resource_group.main.location
    network_interface_ids = [azurerm_network_interface.main[count.index].id,]
    vm_size               = "Standard_B1s"
    availability_set_id   = azurerm_availability_set.main.id

    # Uncomment this line to delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true

    storage_image_reference {
        id = data.azurerm_image.image.id
    }

    storage_os_disk {
        name              = "${var.prefix}-osdisk${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "${var.prefix}-vm${count.index}"
        admin_username = var.username
        admin_password = var.password
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        Envirnoment = "C1 - Infrastructure"
    }
}
