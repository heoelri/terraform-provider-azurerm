package cdn_test

import (
	"context"
	"fmt"
	"testing"

	"github.com/hashicorp/terraform-provider-azurerm/internal/acceptance"
	"github.com/hashicorp/terraform-provider-azurerm/internal/acceptance/check"
	"github.com/hashicorp/terraform-provider-azurerm/internal/clients"
	"github.com/hashicorp/terraform-provider-azurerm/internal/services/cdn/parse"
	"github.com/hashicorp/terraform-provider-azurerm/internal/tf/pluginsdk"
	"github.com/hashicorp/terraform-provider-azurerm/utils"
)

type CdnFrontdoorSecretResource struct{}

func TestAccCdnFrontdoorSecret_basic(t *testing.T) {
	data := acceptance.BuildTestData(t, "azurerm_cdn_frontdoor_secret", "test")
	r := CdnFrontdoorSecretResource{}
	data.ResourceTest(t, r, []acceptance.TestStep{
		{
			Config: r.basic(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
			),
		},
		data.ImportStep(),
	})
}

func TestAccCdnFrontdoorSecret_requiresImport(t *testing.T) {
	data := acceptance.BuildTestData(t, "azurerm_cdn_frontdoor_secret", "test")
	r := CdnFrontdoorSecretResource{}
	data.ResourceTest(t, r, []acceptance.TestStep{
		{
			Config: r.basic(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
			),
		},
		data.RequiresImportErrorStep(r.requiresImport),
	})
}

func TestAccCdnFrontdoorSecret_complete(t *testing.T) {
	data := acceptance.BuildTestData(t, "azurerm_cdn_frontdoor_secret", "test")
	r := CdnFrontdoorSecretResource{}
	data.ResourceTest(t, r, []acceptance.TestStep{
		{
			Config: r.complete(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
			),
		},
		data.ImportStep(),
	})
}

func TestAccCdnFrontdoorSecret_update(t *testing.T) {
	data := acceptance.BuildTestData(t, "azurerm_cdn_frontdoor_secret", "test")
	r := CdnFrontdoorSecretResource{}
	data.ResourceTest(t, r, []acceptance.TestStep{
		{
			Config: r.complete(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
			),
		},
		data.ImportStep(),
		{
			Config: r.update(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
			),
		},
		data.ImportStep(),
	})
}

func (r CdnFrontdoorSecretResource) Exists(ctx context.Context, clients *clients.Client, state *pluginsdk.InstanceState) (*bool, error) {
	id, err := parse.FrontdoorSecretID(state.ID)
	if err != nil {
		return nil, err
	}

	client := clients.Cdn.FrontdoorSecretsClient
	resp, err := client.Get(ctx, id.ResourceGroup, id.ProfileName, id.SecretName)
	if err != nil {
		if utils.ResponseWasNotFound(resp.Response) {
			return utils.Bool(false), nil
		}
		return nil, fmt.Errorf("retrieving %s: %+v", id, err)
	}
	return utils.Bool(true), nil
}

func (r CdnFrontdoorSecretResource) template(data acceptance.TestData) string {
	return fmt.Sprintf(`
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-cdn-afdx-%d"
  location = "%s"
}

resource "azurerm_cdn_frontdoor_profile" "test" {
  name                = "acctest-c-%d"
  resource_group_name = azurerm_resource_group.test.name
}
`, data.RandomInteger, data.Locations.Primary, data.RandomInteger)
}

func (r CdnFrontdoorSecretResource) basic(data acceptance.TestData) string {
	template := r.template(data)
	return fmt.Sprintf(`
				%s

resource "azurerm_cdn_frontdoor_secret" "test" {
  name                     = "acctest-c-%d"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.test.id
  parameters {
    type = ""
  }
}
`, template, data.RandomInteger)
}

func (r CdnFrontdoorSecretResource) requiresImport(data acceptance.TestData) string {
	config := r.basic(data)
	return fmt.Sprintf(`
			%s

resource "azurerm_cdn_frontdoor_secret" "import" {
  name                     = azurerm_cdn_frontdoor_secret.test.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.test.id
  parameters {
    type = ""
  }
}
`, config)
}

func (r CdnFrontdoorSecretResource) complete(data acceptance.TestData) string {
	template := r.template(data)
	return fmt.Sprintf(`
			%s

resource "azurerm_cdn_frontdoor_secret" "test" {
  name                     = "acctest-c-%d"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.test.id
  parameters {
    type = ""
  }
}
`, template, data.RandomInteger)
}

func (r CdnFrontdoorSecretResource) update(data acceptance.TestData) string {
	template := r.template(data)
	return fmt.Sprintf(`
			%s

resource "azurerm_cdn_frontdoor_secret" "test" {
  name                     = "acctest-c-%d"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.test.id
}
`, template, data.RandomInteger)
}
