defmodule AppCount.Acceptance.CreateAccountTest do
  @moduledoc """

  """
  use AppCountWeb.ConnCase, async: true

  alias AppCount.Core.SoftLedgerTranslationTopic
  alias AppCount.Finance.AccountRepo
  alias AppCount.Core.DomainEvent

  #
  # -- TO RUN THIS TEST  --
  # delete or (comment out) lines in config/test.exs for:
  #
  #    tasker: AppCount.Support.Adapters.SkipTask
  #    pub_sub: AppCount.Support.Adapters.PubSubFake,
  #    softledger: AppCount.Support.Adapters.SoftLedgerFake
  #
  # THEN RUN
  #
  # MIX_ENV=test mix compile --force &&
  # mix test test/acceptance/create_account.exs --include acceptance_test
  #

  @moduletag :acceptance_test
  setup(~M[conn]) do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_super_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    conn = admin_request(conn, admin)

    ~M[conn]
  end

  describe "create/2" do
    @tag subdomain: "administration"
    test "succeeds", ~M[conn] do
      SoftLedgerTranslationTopic.subscribe()

      params = %{
        name: "Some Account",
        number: "12345678",
        natural_balance: "credit",
        type: "Asset",
        description: "This is an account"
      }

      # When
      conn = post(conn, Routes.api_finance_account_path(conn, :create), params)
      assert body = json_response(conn, 201)
      assert account_id = body["data"]["id"]
      assert_receive %DomainEvent{name: "created", topic: "soft_ledger__translations"}, 4000

      # Cleanup
      AccountRepo.delete(account_id)
    end
  end
end
