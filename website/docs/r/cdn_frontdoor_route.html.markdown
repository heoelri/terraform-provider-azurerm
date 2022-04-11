---
subcategory: "CDN"
layout: "azurerm"
page_title: "Azure Resource Manager: azurerm_cdn_frontdoor_route"
description: |-
  Manages a Frontdoor Route.
---

# azurerm_cdn_frontdoor_route

Manages a Frontdoor Route.

## Example Usage

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-cdn-frontdoor"
  location = "West Europe"
}

resource "azurerm_cdn_frontdoor_profile" "example" {
  name                = "example-profile"
  resource_group_name = azurerm_resource_group.example.name
}

resource "frontdoor_origin_group" "example" {
  name                     = "example-originGroup"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}

resource "azurerm_frontdoor_endpoint" "example" {
  name                     = "example-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.example.id
}

resource "azurerm_cdn_frontdoor_route" "example" {
  name                          = "example-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.example.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.example.id
  enabled                       = true

  cdn_frontdoor_origin_ids   = [azurerm_cdn_frontdoor_origin.example.id]
  forwarding_protocol        = "HttpsOnly"
  https_redirect             = true
  link_to_default_domain     = true
  patterns_to_match          = ["/*"]
  supported_protocols        = ["Http", "Https"]
  cdn_frontdoor_rule_set_ids = [azurerm_cdn_frontdoor_rule_set.example.id]

  cache_configuration {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}
```

## Arguments Reference

The following arguments are supported:

* `name` - (Required) The name which should be used for this Frontdoor Route. Changing this forces a new Frontdoor Route to be created.

* `cdn_frontdoor_endpoint_id` - (Required) The ID of the Frontdoor Route. Changing this forces a new Frontdoor Route to be created.

* `cdn_frontdoor_origin_group_id` - (Required) The resource ID of the Frontdoor Origin Group. Changing this forces a new Frontdoor Route to be created.

* `cdn_frontdoor_origin_ids` - (Required) One or more Frontdoor Origin resource IDs this Frontdoor Route will link to. Changing this forces a new Frontdoor Route to be created.

* `supported_protocols` - (Required) One or more Protocols supported by this Frontdoor Route. Possible values are `Http` or `Https`.

* `patterns_to_match` - (Reqired) The route patterns of the rule.

* `cache_configuration` - (Optional) A `cache_configuration` block as defined below.

~> **NOTE:** To to disable caching, do not provide the `cache_configuration` block in the configuration file. 

* `enabled` - (Optional) Is this Frontdoor Route enabled? Possible values are `true` or `false`. Defaults to `true`.

* `forwarding_protocol` - (Optional) The Protocol that will be use when forwarding traffic to backends. Possible values are `HttpOnly`, `HttpsOnly` or `MatchRequest`. Defaults to `MatchRequest`.

* `https_redirect` - (Optional) Automatically redirect HTTP traffic to HTTPS traffic? Possible values are `true` or `false`. Defaults to `true`.

~> **NOTE:** The `https_redirect` rule is the first rule that will be executed.

* `link_to_default_domain` - (Optional) Will this route be linked to the default domain endpoint? Possible values are `true` or `false`. Defaults to `true`.

->**NOTE:** On initial creation of the Frontdoor Route resource in Terraform this value must always be set to `true` due to the Custom Domain workflow logic and the creation constraints of the Frontdoor Route resource that have been introduced with this version of Frontdoor.

* `cdn_frontdoor_origin_path` - (Optional) A directory path on the origin that Frontdoor can use to retrieve content from(e.g. contoso.cloudapp.net/originpath).

* `cdn_frontdoor_rule_set_ids` - (Optional) One or more Frontdoor Rule Set Resource ID's.

---

A `cache_configuration` block supports the following:

* `query_string_caching_behavior` - (Optional) Defines how the Frontdoor will cache requests that include query strings. Possible values include `IgnoreQueryString`, `IgnoreSpecifiedQueryStrings`, `IncludeSpecifiedQueryStrings` or `UseQueryString`. Defaults it `IgnoreQueryString`.

~> **NOTE:** The value of the `query_string_caching_behavior` determines if the `query_strings` field will be used as an include list or an ignore list.

* `query_strings` - (Optional) Query strings to include or ignore.

* `compression_enabled` - (Optional) Is content compression enabled? Possible values are `true` or `false`. Defaults to `false`. 

~> **NOTE:** Content won't be compressed when the requested content is smaller than `1 KB` or larger than `8 MB`(inclusive).

* `content_types_to_compress` - (Optional) A list of one or more `Content types` (formerly known as `MIME types`) to compress. Possible values include `application/eot`, `application/font`, `application/font-sfnt`, `application/javascript`, `application/json`, `application/opentype`, `application/otf`, `application/pkcs7-mime`, `application/truetype`, `application/ttf`, `application/vnd.ms-fontobject`, `application/xhtml+xml`, `application/xml`, `application/xml+rss`, `application/x-font-opentype`, `application/x-font-truetype`, `application/x-font-ttf`, `application/x-httpd-cgi`, `application/x-mpegurl`, `application/x-opentype`, `application/x-otf`, `application/x-perl`, `application/x-ttf`, `application/x-javascript`, `font/eot`, `font/ttf`, `font/otf`, `font/opentype`, `image/svg+xml`, `text/css`, `text/csv`, `text/html`, `text/javascript`, `text/js`, `text/plain`, `text/richtext`, `text/tab-separated-values`, `text/xml`, `text/x-script`, `text/x-component` or `text/x-java-source`.

## Attributes Reference

In addition to the Arguments listed above - the following Attributes are exported:

* `id` - The ID of the Frontdoor Route.

* `frontdoor_endpoint_name` - The name of the Frontdoor Endpoint which holds the Frontdoor Route.

---

## Timeouts

The `timeouts` block allows you to specify [timeouts](https://www.terraform.io/docs/configuration/resources.html#timeouts) for certain actions:

* `create` - (Defaults to 30 minutes) Used when creating the Frontdoor Route.
* `read` - (Defaults to 5 minutes) Used when retrieving the Frontdoor Route.
* `update` - (Defaults to 30 minutes) Used when updating the Frontdoor Route.
* `delete` - (Defaults to 30 minutes) Used when deleting the Frontdoor Route.

## Import

Frontdoor Routes can be imported using the `resource id`, e.g.

```shell
terraform import azurerm_cdn_frontdoor_route.example /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resourceGroup1/providers/Microsoft.Cdn/profiles/profile1/afdEndpoints/endpoint1/routes/route1
```
