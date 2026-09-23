terraform {
    reqiured_version = ">=1.5.0"
    reqiured_providers {
        azurerm ={
            soure = "hashicorp/azurerm
            version = "~>4.0"
        }
    }
}

provider azurerm {
    features{}
}