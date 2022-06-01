defmodule AppCount.Accounts.Utils.PaymentSourcesTest do
  use AppCount.DataCase
  alias AppCount.Support.AccountBuilder
  alias AppCount.Accounts.Utils.PaymentSources
  @moduletag :payment_sources

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()

    property =
      builder
      |> PropBuilder.get_requirement(:property)

    tenant =
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_lease()
      |> PropBuilder.get_requirement(:tenant)

    payment_source =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.get_requirement(:payment_source)

    ~M[payment_source, tenant]
  end

  describe "cc_processor_for_tenant(nil)" do
    test "nil cc returns nil" do
      assert {:error, "Payment processor not configured"} ==
               PaymentSources.cc_processor_for_tenant(nil)
    end
  end

  describe "cc_processor_for_tenant(%AppCount.Accounts.Account{} = account)" do
    test "Account map returns processor", ~M[payment_source] do
      {:ok, processor} = PaymentSources.cc_processor_for_tenant(payment_source)
      assert processor.type == "cc"
    end
  end

  describe "cc_processor_for_tenant(tenant_id)" do
    test "Account map returns processor", ~M[tenant] do
      {:ok, processor} = PaymentSources.cc_processor_for_tenant(tenant.id)
      assert processor.type == "cc"
    end
  end

  describe "convert_params(%{'brand' => _} = params)" do
    test "presence of 'brand' as a key should trigger conversions" do
      converted_map =
        %{"brand" => "The key to this should be :brand"}
        |> PaymentSources.convert_params()

      assert %{brand: "The key to this should be :brand"} = converted_map
    end
  end

  describe "convert_params(_)" do
    test "returns empty map for bad input" do
      hopefully_empty_map = PaymentSources.convert_params("wrong input")
      assert hopefully_empty_map == %{}
    end
  end

  describe "lock_payment_source/2" do
    test "successfully locks", ~M[payment_source] do
      {:ok, post_lock_payment_source} = PaymentSources.lock_payment_source(payment_source.id)

      refute is_nil(post_lock_payment_source.lock)
      assert Timex.is_valid?(post_lock_payment_source.lock)
    end
  end

  describe "delete_payment_source" do
    test "delete_payment_source", ~M[payment_source] do
      AppCount.Accounts.delete_payment_source(payment_source.id)
      refute Repo.get(AppCount.Accounts.PaymentSource, payment_source.id)
    end
  end
end
