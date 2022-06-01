defmodule AppCountWeb.Users.API.V1.AutoPayControllerTest do
  alias AppCountWeb.Users.API.V1.AutoPayController, as: Controller
  alias Ecto.Changeset
  use AppCountWeb.ConnCase

  # simple stub to echo back (i.e. parrot) the function call
  defmodule OkAccountsParrot do
    use TestParrot
    # function name, when called send message to self() i.e. this test process
    #        scope     function        default-returns-value
    parrot(:accounts, :create_autopay, {:ok, :ignored})
  end

  defmodule ErrorAccountsParrot do
    use TestParrot

    parrot(
      :accounts,
      :create_autopay,
      {:error,
       Changeset.change(%AppCount.Accounts.Autopay{}, %{payment_source_id: "abcdefg"})
       |> Changeset.add_error(:payment_source_id, "cannot be a string")}
    )
  end

  setup(~M[conn]) do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    # defined inAppCount.Accounts.Utils.Tokens.user_info(uuid)
    user = %{
      account_id: 17762,
      alarm_code: nil,
      autopay: false,
      email: "someguy3@yahoo.com",
      encrypted_password: "$2b$12$WHDiBMr/wbg/2h1rE.BvduY9p59zmtI6L2wC4uf7VlGrqusRkgyga",
      first_name: "Larry-3",
      # Tenant ID
      id: 79759,
      last_name: "Smith",
      name: "Larry-3 Smith",
      password_changed: false,
      payment_status: "approved",
      phone: nil,
      profile_pic: nil,
      property: %{icon: nil, id: 237_805, logo: nil, name: "Test Property"},
      receives_mailings: true,
      uuid: "1016200f-372a-4776-a7c2-f2f577489ba4"
    }

    formatted_ip_address = "127.0.0.1"

    conn =
      conn
      |> assign(:user, user)
      |> assign(:formatted_ip_address, formatted_ip_address)

    params = %{
      "account_id" => account.id,
      "payment_source_id" => 12345,
      "active" => "true"
    }

    {:ok, now} = DateTime.now("Etc/UTC")
    ~M[conn, now, params]
  end

  test "create 200", ~M[conn, now, params] do
    deps = %{
      accounts: OkAccountsParrot,
      agreement_text_for_fn: fn _property -> "agreement text goes here" end,
      utc_now_fn: fn _time_zone -> {:ok, now} end
    }

    # When
    result = Controller.create(conn, %{"autopay" => params}, deps)

    # Then
    assert_receive {:create_autopay, params}
    assert params.account_id == 17762
    assert params.active == "true"
    assert params.agreement_accepted_at == now |> DateTime.to_iso8601()
    assert params.agreement_text == "agreement text goes here"
    assert params.payer_ip_address == "127.0.0.1"
    assert params.payment_source_id
    assert params.status == "approved"
    # And
    assert result.status == 200
  end

  test "create 433", ~M[conn, now, params] do
    deps = %{
      accounts: ErrorAccountsParrot,
      agreement_text_for_fn: fn _property -> "agreement text goes here" end,
      utc_now_fn: fn _time_zone -> {:ok, now} end
    }

    # When
    result = Controller.create(conn, %{"autopay" => params}, deps)

    # Then
    assert result.status == 422
    assert result.resp_body == "{\"error\":{\"payment_source_id\":[\"cannot be a string\"]}}"
  end
end
