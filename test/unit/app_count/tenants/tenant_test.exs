defmodule AppCount.Tenants.TenantTest do
  use AppCount.DataCase
  alias AppCount.Tenants.Tenant
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Support.AccountBuilder

  def new_tenant() do
    Tenant.new("Mickey", "Mouse")
    |> Map.put(:invalid_phone, "123")
  end

  test "create" do
    assert new_tenant()
  end

  describe "changeset" do
    setup do
      tenant = new_tenant()
      ~M[tenant]
    end

    test "update invalid_phone", ~M[tenant] do
      expected = "+15551112222"
      changeset = Tenant.changeset(tenant, %{invalid_phone: expected})
      assert changeset.changes.invalid_phone == expected
      assert changeset.valid?
    end

    test "canonical invalid_phone", ~M[tenant] do
      noncanonical_invalid_phone = "(555) 111-2222"
      canonical_invalid_phone = "+15551112222"
      changeset = Tenant.changeset(tenant, %{invalid_phone: noncanonical_invalid_phone})
      assert changeset.changes.invalid_phone == canonical_invalid_phone
      assert changeset.valid?
    end

    test "blank invalid_phone", ~M[tenant] do
      blank_invalid_phone = ""
      changeset = Tenant.changeset(tenant, %{invalid_phone: blank_invalid_phone})
      assert changeset.changes.invalid_phone == blank_invalid_phone
      assert changeset.valid?
    end

    test "nil invalid_phone", ~M[tenant] do
      nil_invalid_phone = nil
      blank_invalid_phone = ""
      changeset = Tenant.changeset(tenant, %{invalid_phone: nil_invalid_phone})
      assert changeset.changes.invalid_phone == blank_invalid_phone
      assert changeset.valid?
    end
  end

  describe "changeset clean-up email" do
    setup do
      tenant = new_tenant()
      ~M[tenant]
    end

    test "valid email", ~M[tenant] do
      changeset = Tenant.changeset(tenant, %{email: "Mickey@mouse.com"})
      assert changeset.changes.email == "Mickey@mouse.com"
      assert changeset.valid?
    end

    test "email with leading space", ~M[tenant] do
      changeset = Tenant.changeset(tenant, %{email: "  Mickey@mouse.com"})
      assert changeset.changes.email == "Mickey@mouse.com"
      assert changeset.valid?
    end

    test "email with trailing spaces", ~M[tenant] do
      changeset = Tenant.changeset(tenant, %{email: "Mickey@mouse.com   "})
      assert changeset.changes.email == "Mickey@mouse.com"
      assert changeset.valid?
    end

    test "email with trailing space and other junk", ~M[tenant] do
      changeset = Tenant.changeset(tenant, %{email: " Mickey@mouse.com -- donald@duck.com"})
      assert changeset.changes.email == "Mickey@mouse.com"
      assert changeset.valid?
    end
  end

  test "changeset" do
    tenant = new_tenant()

    changeset = Tenant.changeset(tenant, %{first_name: "Elon"})
    assert changeset.valid?
  end

  test "store in db" do
    tenant = new_tenant()

    result =
      Tenant.changeset(tenant, %{first_name: "Elon"})
      |> AppCount.Repo.insert()

    assert {:ok, stored_tenant} = result
    assert stored_tenant.id
    assert stored_tenant.inserted_at
    assert stored_tenant.first_name == "Elon"
  end

  describe "autopay?/1" do
    setup do
      [_builder, property, tenant] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_processor()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()
        |> PropBuilder.get([:property, :tenant])

      [account_builder, account] =
        AccountBuilder.new(:create)
        |> AccountBuilder.put_requirement(:tenant, tenant)
        |> AccountBuilder.put_requirement(:property, property)
        |> AccountBuilder.add_account()
        |> AccountBuilder.get([:account])

      ~M[tenant, account, account_builder]
    end

    test "with no autopay", ~M[tenant] do
      {:ok, tenant} = TenantRepo.aggregate(tenant.id)

      # WHEN
      refute AppCount.Tenants.Tenant.autopay?(tenant)
    end

    test "with active autopay", ~M[tenant, account_builder] do
      account_builder
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.add_autopay()

      {:ok, tenant} = TenantRepo.aggregate(tenant.id)

      # WHEN
      assert AppCount.Tenants.Tenant.autopay?(tenant)
    end

    test "with inactive autopay", ~M[tenant, account_builder] do
      account_builder
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.add_autopay(active: false)

      {:ok, tenant} = TenantRepo.aggregate(tenant.id)

      # WHEN
      refute AppCount.Tenants.Tenant.autopay?(tenant)
    end
  end
end
