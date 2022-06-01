defmodule AppCount.Accounting.PaymentAnalyticsRepoTest do
  use AppCount.DataCase
  alias AppCount.Accounting.PaymentAnalyticsRepo
  alias AppCount.Core.DateTimeRange
  alias AppCount.Support.AccountBuilder

  setup do
    [builder, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.get([:property])

    ~M[builder, property]
  end

  def dates() do
    times =
      AppTime.new()
      |> AppTime.start_of_month()
      |> AppTime.plus(:now, minutes: 0)
      |> AppTime.times()

    DateTimeRange.list_to_date_time_range([times.start_of_month, times.now])
  end

  def add_payments(builder, num) do
    1..num
    |> Enum.each(fn _ -> PropBuilder.add_payment(builder) end)
  end

  describe "get_payments_in_range/2" do
    setup(~M[builder]) do
      builder =
        builder
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy()
        |> PropBuilder.add_payment()

      dates = dates()

      ~M[builder, dates]
    end

    test "one payment", ~M[property, dates] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      res = PaymentAnalyticsRepo.get_payments_in_range(dates, [property.id], client.client_schema)

      assert length(res) == 1
    end

    test "multiple payments", ~M[builder, property, dates] do
      add_payments(builder, 4)
      client = AppCount.Public.get_client_by_schema("dasmen")

      res = PaymentAnalyticsRepo.get_payments_in_range(dates, [property.id], client.client_schema)

      assert length(res) == 5
    end
  end

  describe "with payments outisde date range" do
    setup(~M[builder]) do
      naive_times =
        AppTime.new()
        |> AppTime.start_of_month()
        |> AppTime.plus_to_naive(:prev_month, months: -2)
        |> AppTime.plus_to_naive(:next_month, months: 1)
        |> AppTime.times()

      builder =
        builder
        |> PropBuilder.add_payment(inserted_at: naive_times.prev_month)
        |> PropBuilder.add_payment(inserted_at: naive_times.next_month)

      ~M[builder, dates()]
    end

    test "multiple payments some outside range", ~M[builder, property, dates] do
      add_payments(builder, 4)
      # There is now 6 payments in the "DB"

      client = AppCount.Public.get_client_by_schema("dasmen")

      res = PaymentAnalyticsRepo.get_payments_in_range(dates, [property.id], client.client_schema)

      assert length(res) == 4
    end
  end

  describe "tenants_with_autopay/1" do
    setup(~M[builder]) do
      [builder, tenant] =
        builder
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy()
        |> PropBuilder.get([:tenant])

      ~M[builder, tenant]
    end

    test "no active autopays", ~M[property] do
      client = AppCount.Public.get_client_by_schema("dasmen")
      res = PaymentAnalyticsRepo.tenants_with_autopay([property.id], client.client_schema)

      assert length(res) == 0
    end

    test "with tenant but in-active autopays", ~M[property, tenant] do
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.add_autopay(active: false)

      client = AppCount.Public.get_client_by_schema("dasmen")
      res = PaymentAnalyticsRepo.tenants_with_autopay([property.id], client.client_schema)
      assert length(res) == 0
    end

    test "with tenant and active autopay", ~M[property, tenant] do
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.add_autopay()

      client = AppCount.Public.get_client_by_schema("dasmen")
      res = PaymentAnalyticsRepo.tenants_with_autopay([property.id], client.client_schema)

      assert length(res) == 1
    end
  end

  describe "tenants_with_no_login/1" do
    setup(~M[builder]) do
      builder =
        builder
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy()

      ~M[builder]
    end

    test "tenant has no account (so no login)", ~M[property] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      res = PaymentAnalyticsRepo.tenants_with_no_login([property.id], client.client_schema)

      assert length(res) == 1
    end

    test "tenant has account but no logins", ~M[builder, property] do
      builder
      |> PropBuilder.add_tenant_account()

      client = AppCount.Public.get_client_by_schema("dasmen")

      res = PaymentAnalyticsRepo.tenants_with_no_login([property.id], client.client_schema)

      assert length(res) == 1
    end

    test "tenant has account and at lease 1 login", ~M[builder, property] do
      builder
      |> PropBuilder.add_tenant_account()
      |> PropBuilder.add_account_login()

      client = AppCount.Public.get_client_by_schema("dasmen")

      res = PaymentAnalyticsRepo.tenants_with_no_login([property.id], client.client_schema)

      assert length(res) == 0
    end
  end
end
