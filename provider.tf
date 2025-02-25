terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.18.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "cd36dfff-6e85-4164-b64e-b4078a773259"
  resource_provider_registrations = "none"

  features {
    # Include any required feature flags here
  }
}
