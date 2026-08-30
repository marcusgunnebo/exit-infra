terraform {
  backend "azurerm" {
    key              = "prod.tfstate"
    use_azuread_auth = true
  }
}
