defmodule AppCount.ShortCodes.TenantsTest do
  use AppCount.DataCase
  alias AppCount.ShortCodes.Tenants
  alias AppCount.Tenants.Tenant

  # @short_codes [
  #   "CURRENT_DATE",
  #   "CURRENT_DATE_TIME",
  #   "FULL_NAME",
  #   "FIRST_NAME",
  #   "LAST_NAME",
  #   "CURRENT_BALANCE",
  #   "PROPERTY_NAME",
  #   "PROPERTY_ADDRESS",
  #   "PROPERTY_ADDRESS_FULL",
  #   "PROPERTY_ADDRESS_REMAINING",
  #   "PROPERTY_WEBSITE",
  #   "PROPERTY_PHONE",
  #   "PROPERTY_GROUP_EMAIL",
  #   "PROPERTY_APP_FEE",
  #   "PROPERTY_ADMIN_FEE",
  #   "PROPERTY_NOTICE_PERIOD",
  #   "PROPERTY_GRACE_PERIOD",
  #   "PROPERTY_LATE_FEE",
  #   "UNIT_NUMBER",
  #   "UNIT_ADDRESS",
  #   "UNIT_MARKET_RENT",
  #   "START_CURRENT_MONTH",
  #   "RECURRING_CHARGES",
  #   "EMAIL",
  #   "REWARDS_BALANCE",
  #   "LEASE_START",
  #   "LEASE_END",
  #   "MONEYGRAM_ACCOUNT"
  # ]

  def html_wrap(short_code) do
    "<p><a href=\"undefined\" class=\"wysiwyg-mention\" data-mention data-value=\"#{short_code}\">@#{
      short_code
    }</a></p>\n>"
  end

  setup do
    [_builder, tenant, unit, property, tenancy] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property(%{
        website: "green-acres.com",
        phone: "555-555-1234",
        group_email: "group@green-acres.com"
      })
      |> PropBuilder.add_property_setting()
      |> PropBuilder.add_unit(%{address: %{street: "1234 Main St"}})
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.add_ledger_charge()
      |> PropBuilder.add_lease()
      |> PropBuilder.get([:tenant, :unit, :property, :tenancy])

    ~M[tenant, unit, property, tenancy]
  end

  describe "parse_short_codes/2" do
    test "empty", ~M[tenancy] do
      body = ""
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == ""
    end

    test "CURRENT_DATE", ~M[tenancy] do
      body = html_wrap("CURRENT_DATE")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{AppCount.current_date()}</span></p>\n&gt;"
    end

    test "CURRENT_DATE_TIME", ~M[tenancy] do
      expected_time = Clock.now() |> Clock.to_nyc()
      body = html_wrap("CURRENT_DATE_TIME")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{expected_time}</span></p>\n&gt;"
    end

    test "FULL_NAME", ~M[tenant, tenancy] do
      body = html_wrap("FULL_NAME")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{Tenant.full_name(tenant)}</span></p>\n&gt;"
    end

    test "FIRST_NAME", ~M[tenant, tenancy] do
      body = html_wrap("FIRST_NAME")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{tenant.first_name}</span></p>\n&gt;"
    end

    test "LAST_NAME", ~M[tenant, tenancy] do
      body = html_wrap("LAST_NAME")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{tenant.last_name}</span></p>\n&gt;"
    end

    test "CURRENT_BALANCE", ~M[tenancy] do
      body = html_wrap("CURRENT_BALANCE")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>950.00</span></p>\n&gt;"
    end

    test "PROPERTY_NAME", ~M[tenancy, property] do
      body = html_wrap("PROPERTY_NAME")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{property.name}</span></p>\n&gt;"
    end

    test "PROPERTY_ADDRESS", ~M[tenancy] do
      body = html_wrap("PROPERTY_ADDRESS")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>3317 Magnolia Hill Dr</span></p>\n&gt;"
    end

    test "PROPERTY_ADDRESS_FULL", ~M[tenancy] do
      body = html_wrap("PROPERTY_ADDRESS_FULL")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>3317 Magnolia Hill Dr, Charlotte, NC 28205</span></p>\n&gt;"
    end

    test "PROPERTY_ADDRESS_REMAINING", ~M[tenancy] do
      body = html_wrap("PROPERTY_ADDRESS_REMAINING")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>Charlotte, NC 28205</span></p>\n&gt;"
    end

    test "PROPERTY_WEBSITE", ~M[tenancy] do
      body = html_wrap("PROPERTY_WEBSITE")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>green-acres.com</span></p>\n&gt;"
    end

    test "PROPERTY_PHONE", ~M[tenancy] do
      body = html_wrap("PROPERTY_PHONE")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>555-555-1234</span></p>\n&gt;"
    end

    test "PROPERTY_GROUP_EMAIL", ~M[tenancy] do
      body = html_wrap("PROPERTY_GROUP_EMAIL")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>group@green-acres.com</span></p>\n&gt;"
    end

    test "PROPERTY_APP_FEE", ~M[tenancy] do
      body = html_wrap("PROPERTY_APP_FEE")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>50</span></p>\n&gt;"
    end

    test "PROPERTY_ADMIN_FEE", ~M[tenancy] do
      body = html_wrap("PROPERTY_ADMIN_FEE")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>150</span></p>\n&gt;"
    end

    test "PROPERTY_NOTICE_PERIOD", ~M[tenancy] do
      body = html_wrap("PROPERTY_NOTICE_PERIOD")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>30</span></p>\n&gt;"
    end

    test "PROPERTY_LATE_FEE", ~M[tenancy] do
      body = html_wrap("PROPERTY_LATE_FEE")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>50</span></p>\n&gt;"
    end

    test "UNIT_NUMBER", ~M[tenancy, unit] do
      body = html_wrap("UNIT_NUMBER")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{unit.number}</span></p>\n&gt;"
    end

    test "UNIT_ADDRESS", ~M[tenancy] do
      body = html_wrap("UNIT_ADDRESS")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>1234 Main St</span></p>\n&gt;"
    end

    test "UNIT_MARKET_RENT", ~M[tenancy] do
      body = html_wrap("UNIT_MARKET_RENT")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>250</span></p>\n&gt;"
    end

    test "RECURRING_CHARGES", ~M[tenancy] do
      # Tests a blank field.
      # Data Model needs to be simplified first
      body = html_wrap("RECURRING_CHARGES")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span></span></p>\n&gt;"
    end

    test "EMAIL", ~M[tenant, tenancy] do
      body = html_wrap("EMAIL")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{tenant.email}</span></p>\n&gt;"
    end

    test "REWARDS_BALANCE", ~M[tenancy] do
      body = html_wrap("REWARDS_BALANCE")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>0</span></p>\n&gt;"
    end

    test "LEASE_START", ~M[tenancy] do
      yesterday = Clock.today({-1, :days})
      body = html_wrap("LEASE_START")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{yesterday}</span></p>\n&gt;"
    end

    test "LEASE_END", ~M[tenancy] do
      next_year = Clock.today({365, :days})
      body = html_wrap("LEASE_END")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{next_year}</span></p>\n&gt;"
    end

    test "MONEYGRAM_ACCOUNT", ~M[tenant, property, tenancy] do
      account = "#{String.pad_leading("#{property.id}", 4, "0000")}#{tenant.id}"

      body = html_wrap("MONEYGRAM_ACCOUNT")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{account}</span></p>\n&gt;"
    end

    test "PROPERTY_GRACE_PERIOD", ~M[tenancy, property] do
      body = html_wrap("PROPERTY_GRACE_PERIOD")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{property.setting.grace_period}</span></p>\n&gt;"
    end

    test "START_CURRENT_MONTH", ~M[tenancy] do
      body = html_wrap("START_CURRENT_MONTH")
      result = Tenants.parse_short_codes(body, %{tenant_id: tenancy.id})
      assert result == "<p><span>#{Clock.beginning_of_month()}</span></p>\n&gt;"
    end
  end
end
