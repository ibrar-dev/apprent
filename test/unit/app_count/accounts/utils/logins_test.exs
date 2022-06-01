defmodule AppCount.Accounts.Utils.LoginsTest do
  use AppCount.DataCase
  alias AppCount.Accounts.Login
  alias AppCount.Accounts.Utils.Logins
  alias AppCount.Support.AccountBuilder

  setup do
    [_builder, property, tenant] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_lease()
      |> PropBuilder.get([:property, :tenant])

    tenant_with_account =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.get_requirement(:tenant)
      |> Repo.preload(:account)

    account_id = tenant_with_account.account.id

    ~M[account_id]
  end

  # Username/password
  describe "create_login/1" do
    test "it works without login_metadata", ~M[account_id] do
      params = %{
        type: "app",
        account_id: account_id
      }

      # When
      {:ok, result} = Logins.create_login(params)

      # Then
      assert %Login{account_id: ^account_id, type: "app"} = result
    end

    test "it work with added login_metadata", ~M[account_id] do
      metadata = %{
        model_name: "FooBar",
        os_name: "doom_guy_OS",
        year_class: 2016,
        brand: "Union Aerospace Corporation"
      }

      params = %{
        type: "web",
        account_id: account_id,
        login_metadata: metadata
      }

      # When
      {:ok, result} = Logins.create_login(params)

      # Then
      assert %Login{account_id: ^account_id, type: "web", login_metadata: ^metadata} = result
    end
  end
end
