defmodule AppCount.Acceptance.SmsTest do
  #
  # -- TO RUN THIS TEST  --
  #
  # delete lines in config/test.exs for:
  #    pub_sub: AppCount.Support.Adapters.PubSubFake,
  # AND
  #    config :app_count, :tasker, AppCount.Support.Adapters.SkipTask
  #
  # THEN RUN
  #
  # MIX_ENV=test mix compile --force && mix test test/acceptance/sms_test.exs --include acceptance_test
  #

  @task Application.compile_env(:app_count, :tasker)
  @pub_sub AppCount.adapters(:pub_sub, nil)

  # MUST RUN syncronously !
  use AppCount.DataCase, async: false

  import AppCount.Factory
  alias AppCount.Maintenance.Utils.Orders
  alias AppCount.Accounts.Account
  alias AppCount.Maintenance.OrderRepo
  alias AppCount.Core.SmsTopic

  @moduletag :acceptance_test

  @real_phone_to_receive_sms System.get_env("APPRENT_PERSONAL_SMS_PHONE")
  @system_creds_message """
    Creds Not Configured For External Calls.
    You need to configure system variable with production creds
              export APPRENT_PERSONAL_SMS_PHONE="+15135551234"
              export TWILIO_SID="something"
              export TWILIO_TOKEN="something"
              export TWILIO_PHONE_FROM ="+Twilio provided phone number"
  """

  @application_config_message """
        #
        #  TEST NOT CONFIGURED CORRECTLY
        #
        #  For an "acceptance_test"  Delete the following lines in config/test.exs
        #
        #  pub_sub: AppCount.Support.Adapters.PubSubFake,
        #
        #  config :app_count, :tasker, AppCount.Support.Adapters.SkipTask
        #
        # When these setting are _nil_ then the production values will be set by default.
        # but of course, do not check in config/test.exs like that.
  """

  setup do
    refute @pub_sub, @application_config_message
    refute @task, @application_config_message

    setup_service(:order_topic, AppCount.Core.OrderTopic)
    setup_service(AppCount.Adapters.TwilioAdapter, AppCount.Adapters.TwilioAdapter)
    setup_creds()
    :ok
  end

  def setup_service(key, service) do
    current_sevice = Application.get_env(:app_count, key, service)
    Application.put_env(:app_count, key, service)
    on_exit(fn -> Application.put_env(:app_count, key, current_sevice) end)
  end

  def setup_creds do
    key = AppCount.Adapters.Twilio.Credential
    current_creds = Application.get_env(:app_count, key)
    ~M[sid, token, phone_from] = read_creds_from_system()
    assert sid && token && phone_from, @system_creds_message

    prod_creds = [sid: sid, token: token, phone_from: phone_from]
    :ok = Application.put_env(:app_count, key, prod_creds)

    on_exit(fn -> Application.put_env(:app_count, key, current_creds) end)
  end

  def read_creds_from_system do
    sid = System.get_env("TWILIO_SID")
    token = System.get_env("TWILIO_TOKEN")
    phone_from = System.get_env("TWILIO_PHONE_FROM")
    ~M[sid, token, phone_from]
  end

  def create_account(tenant, property) do
    attrs = %{
      password: "secret agent man",
      tenant_id: tenant.id,
      username: "AccountHolder-#{Enum.random(1..100_000)}",
      property_id: property.id
    }

    account =
      Account.new(attrs)
      |> Account.changeset(%{allow_sms: true})
      |> AppCount.Repo.insert!()

    account
  end

  describe "Start from Orders.create_order" do
    setup do
      admin = AppCount.UserHelper.new_admin()

      tech = insert(:tech, name: "Tommy the Tech")

      property = insert(:property, name: "Message-Test Properties")

      attrs = %{
        first_name: "David",
        last_name: "Tenant",
        allow_sms: true,
        phone: @real_phone_to_receive_sms,
        uuid: Ecto.UUID.generate()
      }

      {:ok, tenant} = AppCount.Tenants.TenantRepo.insert(attrs)

      _account = create_account(tenant, property)

      params = %{
        "note" => "This is a really dumb note.",
        "property_id" => property.id,
        "priority" => 1,
        "entry_allowed" => true,
        "has_pet" => true,
        "tenant_id" => tenant.id,
        "tech" => tech.id,
        "category_id" => insert(:sub_category).id
      }

      ~M[admin,  tech, params]
    end

    test "send real external message to APPRENT_PERSONAL_SMS_PHONE", ~M[admin,  tech, params] do
      # When CREATED and ASSIGNED ---------------------------------
      {:ok, order} = Orders.create_order(admin.id, {"dasmen", params})
      IO.puts("Orders.create_order ...")

      order =
        order
        |> AppCount.Repo.preload(:tenant)

      assert order.tenant.phone == @real_phone_to_receive_sms

      Process.sleep(8000)

      # When DISPATCHED  ---------------------------------
      order = OrderRepo.get_aggregate(order.id)

      [assignment | _] = order.assignments

      AppCount.Maintenance.Utils.Assignments.tech_dispatched(assignment.id, DateTime.utc_now())

      Process.sleep(8000)

      # When COMPLETED  ---------------------------------
      details = %{}
      AppCount.Maintenance.complete_assignment({"dasmen", assignment.id}, details, tech.id)

      IO.puts("Check for SMS on phone #{order.tenant.phone} for 4 messages")

      IO.puts("waiting ...")
      Process.sleep(8000)
      IO.puts("... DONE!")
    end
  end

  describe "phone_from is not env variable" do
    test "SmsTopic.message_sent/2 successfully sends from correct num" do
      IO.puts("Sending Text...")

      SmsTopic.message_sent(
        {"+18557981304", @real_phone_to_receive_sms, "Test Message From AppRent Test"},
        __MODULE__
      )

      IO.puts("Check for SMS on phone
          #{@real_phone_to_receive_sms}
        for 1 message from +18557981304")

      IO.puts("waiting ...")
      Process.sleep(8000)
      IO.puts("... DONE!")
    end
  end
end
