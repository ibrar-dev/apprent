defmodule AppCount.Core.OrderTopic.InfoTest do
  use AppCount.DataCase
  alias AppCount.Core.OrderTopic.Info
  alias AppCount.Maintenance.Order
  alias AppCount.Tenants.Tenant
  alias AppCount.Accounts.Account
  alias AppCount.Maintenance.OrderObserver

  test "valid new" do
    info =
      Info.new(
        %Tenant{phone: "+15135551234"},
        %Account{allow_sms: true},
        %Order{allow_sms: true, category: %{name: "cname"}, property: %{name: "Wayne Manor"}}
      )

    assert info.phone_to == "+15135551234"
    assert info.account_allow_sms == true
    assert info.order_allow_sms == true
  end

  test "phone is nil" do
    info =
      Info.new(
        %Tenant{phone: nil},
        %Account{allow_sms: true},
        %Order{allow_sms: true, category: %{name: "cname"}, property: %{name: "Wayne Manor"}}
      )

    #

    assert info.phone_to == :not_available
    assert info.account_allow_sms == true
    assert info.order_allow_sms == true
    assert info.tech_name == "Tech not yet assigned"
  end

  test "missing account new" do
    info =
      Info.new(%Tenant{phone: "+15135551234"}, nil, %Order{
        allow_sms: true,
        category: %{name: "cname"},
        property: %{name: "Wayne Manor"}
      })

    assert info.phone_to == "+15135551234"
    assert info.account_allow_sms == :no_account
    assert info.order_allow_sms == true
    assert info.tech_name == "Tech not yet assigned"
  end

  test "missing tenant new" do
    info =
      Info.new(nil, nil, %Order{
        allow_sms: true,
        category: %{name: "cname"},
        property: %{name: "Wayne Manor"}
      })

    assert info.phone_to == :not_available
    assert info.account_allow_sms == false
    assert info.order_allow_sms == true
    assert info.tech_name == "Tech not yet assigned"
  end

  describe "eval_string" do
    setup do
      info =
        Info.new(
          %Tenant{phone: "+15135551234", first_name: "HAL"},
          %Account{allow_sms: true},
          %Order{
            allow_sms: true,
            category: %{name: "jammed bay door"},
            property: %{name: "Wayne Manor"}
          }
        )

      info = %{info | tech_name: "David Bowman"}
      ~M[info]
    end

    test "empty string", ~M[info] do
      result = Info.eval_string("", info)
      assert result == ""
    end

    test "string without values", ~M[info] do
      message = "string without values"
      result = Info.eval_string(message, info)
      assert result == message
    end

    test "templated values", ~M[info] do
      expected_message =
        "Hi HAL, Great news! Your work order for jammed bay door has been assigned to David Bowman from Wayne Manor. You will receive another notification in 24-48 hours when  David Bowman is on the way."

      result =
        "order_assigned"
        |> OrderObserver.template_for()
        |> Info.eval_string(info)

      assert result == expected_message
    end
  end
end
