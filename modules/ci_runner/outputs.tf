output "vm_name" {
  value = azurerm_linux_virtual_machine.this.name
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.this.id
}

output "runner_labels" {
  value = var.runner_labels
}
