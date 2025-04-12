resource "azurerm_resource_group" "rg" {
  name     = "${var.workload_name}-rg-wl"
  location = var.location
}

resource "azurerm_virtual_network" "workload_network" {
  name                = "${var.workload_name}-vnet-wl"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.address_space

  dns_servers = var.dns_servers
}

# NOTE: this always means the 0th subnet is taken
resource "azurerm_subnet" "workload_subnet" {
  name                 = "${var.workload_name}-subnet-wl"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.workload_network.name
  address_prefixes = [
    # chop the /18 into 16 /22 subnets
    cidrsubnet(var.address_space[0], 4, 0),
  ]

  default_outbound_access_enabled = false
}

resource "azurerm_virtual_hub_connection" "wl_connection" {
  name                      = "${var.workload_name}-wl-hub-connect"
  virtual_hub_id            = var.virtual_hub_id
  remote_virtual_network_id = azurerm_virtual_network.workload_network.id
  internet_security_enabled = true
  # routing {
  #   associated_route_table_id = var.assc_route_table_id
  #   propagated_route_table {
  #     route_table_ids = var.prop_route_table_ids
  #     labels          = var.prop_route_table_labels
  #   }
  # }
}

resource "azurerm_network_interface" "wl_jumpbox_nic" {
  name                = "wl-jumpbox-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "wl-ipconfig"
    subnet_id                     = azurerm_subnet.workload_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_marketplace_agreement" "ubuntu" {
  publisher = "canonical"
  offer     = "0001-com-ubuntu-pro-jammy-fips"
  plan      = "pro-fips-22_04"
}

data "cloudinit_config" "hardened_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
ubuntu_pro:
  enable: [esm, fips-updates, usg]
packages:
  - usg
  - postgresql-client
runcmd:
  - ["sudo", "userdel", "-r", "dummy-account"]
  - [sudo, usg, fix, disa_stig]
  - [sudo, systemctl, reboot]
EOF
  }
}

resource "azurerm_linux_virtual_machine" "wl_jumpbox" {
  depends_on = [
    azurerm_marketplace_agreement.ubuntu,
    # This connection provides limited internet access to the jumpbox,
    # which is required to STIG the machine automatically
    azurerm_virtual_hub_connection.wl_connection,
    var.firewall_dependency
  ]

  name                = "${var.workload_name}-jumpbox"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Make sure this has at least 1GB of RAM or else cloud-init will mysteriously fail with no logs
  size = "Standard_B1s"

  network_interface_ids = [azurerm_network_interface.wl_jumpbox_nic.id]


  # create this account and immediately delete it in custom_data
  # This public key was generated on a FIPS machine and the corresponding private key was destroyed
  # people should only sign in with AAD
  admin_username                  = "dummy-account"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "dummy-account"
    public_key = file("${path.module}/impossible-public-key.txt")
  }

  custom_data = data.cloudinit_config.hardened_config.rendered

  boot_diagnostics {

  }

  plan {
    name      = "pro-fips-22_04"
    product   = "0001-com-ubuntu-pro-jammy-fips"
    publisher = "canonical"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-pro-jammy-fips"
    sku       = "pro-fips-22_04"
    version   = "22.04.202501280"
  }

  # custom_data = base64encode(<<EOF
  # #!/bin/bash
  # sudo pro enable usg
  # sudo apt install usg
  # sudo usg fix disa_stig
  # EOF
  # )
}

resource "azurerm_virtual_machine_extension" "entra_auth" {
  depends_on = [
    # This connection provides limited internet access to the jumpbox,
    # which is required for the extension to download the AAD SSH login package
    azurerm_virtual_hub_connection.wl_connection,
    var.firewall_dependency
  ]

  publisher            = "Microsoft.Azure.ActiveDirectory"
  name                 = "entra-linux-ssh"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
  virtual_machine_id   = azurerm_linux_virtual_machine.wl_jumpbox.id
}

resource "azurerm_ip_group_cidr" "jumpbox_ip" {
  ip_group_id = var.ip_group_id
  cidr        = azurerm_linux_virtual_machine.wl_jumpbox.private_ip_address
}
