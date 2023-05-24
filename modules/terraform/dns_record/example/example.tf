terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "a" {
  source = "../"

  # cloudflare_zone_id          = var.cloudflare_zone_id
  azurerm_resource_group_name = var.azurerm_resource_group_name
  azurerm_dns_zone_name       = var.azurerm_dns_zone_name
  azurerm_tags                = var.tags
  names                       = ["a_many", "a_many2"]
  targets                     = ["127.0.0.2", "127.0.0.3"]
  ttl                         = var.ttl
}

module "cname" {
  source = "../"

  # cloudflare_zone_id          = var.cloudflare_zone_id
  azurerm_resource_group_name = var.azurerm_resource_group_name
  azurerm_dns_zone_name       = var.azurerm_dns_zone_name
  azurerm_tags                = var.tags
  names                       = ["cname_one", "cname_two"]
  targets                     = ["test.google.com"]
  type                        = "CNAME"
  ttl                         = var.ttl
}

module "txt" {
  source = "../"

  # cloudflare_zone_id          = var.cloudflare_zone_id
  azurerm_resource_group_name = var.azurerm_resource_group_name
  azurerm_dns_zone_name       = var.azurerm_dns_zone_name
  azurerm_tags                = var.tags
  names                       = ["@", "test"]
  targets                     = ["how", "you", "doing"]
  type                        = "TXT"
  ttl                         = var.ttl
}

module "mx" {
  source = "../"

  # cloudflare_zone_id          = var.cloudflare_zone_id
  azurerm_resource_group_name = var.azurerm_resource_group_name
  azurerm_dns_zone_name       = var.azurerm_dns_zone_name
  azurerm_tags                = var.tags
  names                       = ["test_mx1", "test_mx2"]
  targets                     = ["mx1.contoso.com", "mx2.contoso.com"]
  mx_priority                 = [20, 1]
  type                        = "MX"
  ttl                         = var.ttl
}

module "mx_one_priority" {
  source = "../"

  # cloudflare_zone_id          = var.cloudflare_zone_id
  azurerm_resource_group_name = var.azurerm_resource_group_name
  azurerm_dns_zone_name       = var.azurerm_dns_zone_name
  azurerm_tags                = var.tags
  names                       = ["test_mx3", "test_mx4"]
  targets                     = ["mx1.contoso.com", "mx2.contoso.com"]
  type                        = "MX"
  ttl                         = var.ttl
}

module "ns" {
  source = "../"

  # cloudflare_zone_id          = var.cloudflare_zone_id
  azurerm_resource_group_name = var.azurerm_resource_group_name
  azurerm_dns_zone_name       = var.azurerm_dns_zone_name
  azurerm_tags                = var.tags
  names                       = ["test_ns1", "test_ns2"]
  targets                     = ["ns1.contoso.com", "ns2.contoso.com"]
  type                        = "NS"
  ttl                         = var.ttl
}
