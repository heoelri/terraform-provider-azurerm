provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-cdn-frontdoor-example"
  location = "westeurope"
} 

resource "azurerm_cdn_frontdoor_profile" "example" {
  name                = "${var.prefix}-profile"
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "Premium_AzureFrontDoor"

  response_timeout_seconds = 120

  tags = {
    environment = "example"
  }
}

# For this example you will have to redirect your domain hosting
# services DNS NS to use this Azure DNS Zone
resource "azurerm_dns_zone" "example" {
  name                = "example.com" # change this to be your domain name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_cdn_frontdoor_firewall_policy" "example" {
  name                              = "${var.prefix}WAF"
  resource_group_name               = azurerm_resource_group.example.name
	cdn_frontdoor_profile_id          = azurerm_cdn_frontdoor_profile.example.id
	sku_name                          = azurerm_cdn_frontdoor_profile.example.sku_name
  enabled                           = true
  mode                              = "Prevention"
  redirect_url                      = "https://www.contoso.com"
  custom_block_response_status_code = 403
  custom_block_response_body        = "PGh0bWw+CjxoZWFkZXI+PHRpdGxlPkhlbGxvPC90aXRsZT48L2hlYWRlcj4KPGJvZHk+CkhlbGxvIHdvcmxkCjwvYm9keT4KPC9odG1sPg=="

  custom_rule {
    name                           = "Rule1"
    enabled                        = true
    priority                       = 1
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 10
    type                           = "MatchRule"
    action                         = "Block"

    match_condition {
      match_variable     = "RemoteAddr"
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }
  }

  # NOTE: Managed rules are only supported with the Premium_AzureFrontDoor SKU
  managed_rule {
    type    = "DefaultRuleSet"
    version = "preview-0.1"

    override {
      rule_group_name = "PHP"

      rule {
        rule_id = "933111"
        enabled = false
        action  = "Block"
      }
    }
  }

  managed_rule {
    type    = "BotProtection"
    version = "preview-0.1"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "example" {
  name                     = "${var.prefix}SecurityPolicy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.example.id

      association {
        domain {
          cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.contoso.id
        }

        domain {
          cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.fabrikam.id
        }

        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "example" {
  name                            = "${var.prefix}-endpoint"
  cdn_frontdoor_profile_id        = azurerm_cdn_frontdoor_profile.example.id
  enabled                         = true
}

resource "azurerm_cdn_frontdoor_origin_group" "example" {
  name                         = "${var.prefix}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id

  health_probe {
    interval_in_seconds = 240
    path                = "/healthProbe"
    protocol            = "Https"
    request_type        = "GET"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }

  session_affinity                      = true
  restore_traffic_or_new_endpoints_time = 10
}

resource "azurerm_cdn_frontdoor_origin" "example" {
  name                          = "${var.prefix}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id

  health_probes_enabled          = true
  enforce_certificate_name_check = false
  host_name                      = join(".", ["contoso", azurerm_dns_zone.example.name])
  priority                       = 1
  weight                         = 1
}

resource "azurerm_cdn_frontdoor_rule_set" "example" {
  name                     = "${var.prefix}ruleset"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}

resource "azurerm_cdn_frontdoor_rule" "example" {
  depends_on = [azurerm_cdn_frontdoor_origin_group.example, azurerm_cdn_frontdoor_origin.example]

  name                      = "${var.prefix}rule"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.example.id
  order                     = 1
  match_processing_behavior = "Continue"

  actions {
    route_configuration_override_action {
      cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id
      forwarding_protocol           = "HttpsOnly"
      query_string_caching_behavior = "IncludeSpecifiedQueryStrings"
      query_string_parameters       = ["foo", "clientIp={client_ip}"]
      compression_enabled           = true
      cache_behavior                = "OverrideIfOriginMissing"
      cache_duration                = "365.23:59:59"
    }

    url_redirect_action {
      redirect_type        = "PermanentRedirect"
      redirect_protocol    = "MatchRequest"
      query_string         = "clientIp={client_ip}"
      destination_path     = "/exampleredirection"
      destination_hostname = "contoso.com"
      destination_fragment = "UrlRedirect"
    }
  }

  conditions {
    host_name_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["www.contoso.com", "images.contoso.com", "video.contoso.com"]
      transforms       = ["Lowercase", "Trim"]
    }

    is_device_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["Mobile"]
    }

    post_args_condition {
      post_args_name = "customerName"
      operator       = "BeginsWith"
      match_values   = ["J", "K"]
      transforms     = ["Uppercase"]
    }

    request_method_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["DELETE"]
    }

    url_filename_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["media.mp4"]
      transforms       = ["Lowercase", "RemoveNulls", "Trim"]
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "example" {
  name                                   = "${var.prefix}-route"
  cdn_frontdoor_endpoint_id              = azurerm_cdn_frontdoor_endpoint.example.id
  cdn_frontdoor_origin_group_id          = azurerm_cdn_frontdoor_origin_group.example.id
  enabled                                = true

  cdn_frontdoor_origin_ids   = [azurerm_cdn_frontdoor_origin.example.id]
  forwarding_protocol        = "HttpsOnly"
  https_redirect             = true
  link_to_default_domain     = true
  patterns_to_match          = ["/*"]
  supported_protocols        = ["Http", "Https"]
  cdn_frontdoor_rule_set_ids = [azurerm_cdn_frontdoor_rule_set.example.id]

  cache_configuration {
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
    query_strings                 = ["account", "settings"]
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "contoso" {
  name                     = "${var.prefix}-contoso-custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
  dns_zone_id              = azurerm_dns_zone.example.id
  host_name                = join(".", ["contoso", azurerm_dns_zone.example.name])

  tls_settings {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "fabrikam" {
  name                     = "${var.prefix}-fabrikam-custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
  dns_zone_id              = azurerm_dns_zone.example.id
  host_name                = join(".", ["fabrikam", azurerm_dns_zone.example.name])

  tls_settings {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_dns_txt_record" "contoso" {
  name                = join(".", ["_dnsauth", "contoso"])
  zone_name           = azurerm_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.contoso.validation_properties.0.validation_token
  }
}

resource "azurerm_dns_txt_record" "fabrikam" {
  name                = join(".", ["_dnsauth", "fabrikam"])
  zone_name           = azurerm_dns_zone.example.name
  resource_group_name = azurerm_resource_group.example.name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.fabrikam.validation_properties.0.validation_token
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_txt_validator" "contoso" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.contoso.id
  dns_txt_record_id              = azurerm_dns_txt_record.contoso.id
}

resource "azurerm_cdn_frontdoor_custom_domain_txt_validator" "fabrikam" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.fabrikam.id
  dns_txt_record_id              = azurerm_dns_txt_record.fabrikam.id
}

resource "azurerm_cdn_frontdoor_custom_domain_route_association" "example" {
  cdn_frontdoor_route_id = azurerm_cdn_frontdoor_route.example.id

  cdn_frontdoor_custom_domain_txt_validator_ids = [azurerm_cdn_frontdoor_custom_domain_txt_validator.contoso.id, azurerm_cdn_frontdoor_custom_domain_txt_validator.fabrikam.id]
  cdn_frontdoor_custom_domain_ids               = [azurerm_cdn_frontdoor_custom_domain.contoso.id, azurerm_cdn_frontdoor_custom_domain.fabrikam.id]
}

resource "azurerm_cdn_frontdoor_custom_domain_secret_validator" "example" {
  cdn_frontdoor_custom_domain_ids                  = [azurerm_cdn_frontdoor_custom_domain.contoso.id, azurerm_cdn_frontdoor_custom_domain.fabrikam.id]
  cdn_frontdoor_custom_domain_route_association_id = azurerm_cdn_frontdoor_custom_domain_route_association.example.id
}

resource "azurerm_dns_cname_record" "contoso" {
  depends_on = [azurerm_cdn_frontdoor_custom_domain_secret_validator.example]

  name                                           = "contoso"
  zone_name                                      = azurerm_dns_zone.example.name
  resource_group_name                            = azurerm_resource_group.example.name
  ttl                                            = 3600
  record                                         = azurerm_cdn_frontdoor_endpoint.example.host_name
}

resource "azurerm_dns_cname_record" "fabrikam" {
  depends_on = [azurerm_cdn_frontdoor_custom_domain_secret_validator.example]

  name                                           = "fabrikam"
  zone_name                                      = azurerm_dns_zone.example.name
  resource_group_name                            = azurerm_resource_group.example.name
  ttl                                            = 3600
  record                                         = azurerm_cdn_frontdoor_endpoint.example.host_name
}
