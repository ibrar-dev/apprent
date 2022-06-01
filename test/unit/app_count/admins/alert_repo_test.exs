defmodule AppCount.Admins.AlertRepoTest do
  use AppCount.DataCase
  alias AppCount.Admins.AlertRepo
  alias AppCount.Core.ClientSchema

  describe "list_alerts/1" do
    setup do
      [builder, admin] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_admin()
        |> PropBuilder.get([:admin])

      ~M[builder, admin]
    end

    test "empty array", ~M[admin] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      res = AlertRepo.list_alerts(ClientSchema.new(client.client_schema, admin.id))

      assert length(res) == 0
    end

    test "single alert", ~M[builder, admin] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      builder
      |> PropBuilder.add_admin_alert()

      res = AlertRepo.list_alerts(ClientSchema.new(client.client_schema, admin.id))

      assert length(res) == 1
    end

    test "multiple alerts", ~M[builder, admin] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      builder
      |> PropBuilder.add_admin_alert()
      |> PropBuilder.add_admin_alert()

      res = AlertRepo.list_alerts(ClientSchema.new(client.client_schema, admin.id))

      assert length(res) == 2
    end
  end

  describe "list_alerts/2" do
    setup do
      [builder, admin] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_admin()
        |> PropBuilder.get([:admin])

      times =
        AppTime.new()
        |> AppTime.plus_to_naive(:fourteen_days_ago, days: -14)
        |> AppTime.plus_to_naive(:ten_days_ago, days: -10)
        |> AppTime.plus_to_naive(:now, minutes: 0)
        |> AppTime.times()

      ~M[builder, admin, times]
    end

    test "empty array", ~M[admin] do
      client = AppCount.Public.get_client_by_schema("dasmen")
      res = AlertRepo.list_alerts(ClientSchema.new(client.client_schema, admin.id))

      assert length(res) == 0
    end

    test "single alert", ~M[builder, admin] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      builder
      |> PropBuilder.add_admin_alert()

      res = AlertRepo.list_alerts(ClientSchema.new(client.client_schema, admin.id))

      assert length(res) == 1
    end

    # Add alert more than 14 days ago and then 2nd argument is 14 days ago
    test "single alert, mutliple outside date", ~M[builder, admin, times] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      builder
      |> PropBuilder.add_admin_alert()
      |> PropBuilder.add_admin_alert(inserted_at: times.fourteen_days_ago)

      res =
        AlertRepo.list_alerts(
          ClientSchema.new(client.client_schema, admin.id),
          times.ten_days_ago
        )

      assert length(res) == 1
    end
  end
end
