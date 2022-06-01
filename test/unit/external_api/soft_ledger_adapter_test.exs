defmodule AppCount.ExternalApi.SoftLedgerAdapterTest do
  #
  # mix test test/external_api/soft_ledger_adapter_test.exs --include external_api
  #
  #
  # MUST RUN syncronously !
  use AppCount.DataCase, async: false
  alias AppCount.Adapters.SoftLedgerAdapter
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  @moduletag :external_api
  @parent_id AppCount.Adapters.SoftLedger.Config.load().parent_id

  test "fetch_token/1" do
    # When
    {:ok, o_auth_response} = SoftLedgerAdapter.fetch_token()

    # Then
    assert o_auth_response.expires_in == 86400

    assert o_auth_response.access_token |> String.length() == 5891
  end

  test "create_location/1" do
    {:ok, %OAuthResponse{access_token: access_token}} = SoftLedgerAdapter.fetch_token()

    uuid = UUID.uuid4()
    property_name = "SoftLedgerAdapterTest-#{uuid}"

    request = %CreateLocationRequest{
      id: uuid,
      parent_id: @parent_id,
      name: property_name
    }

    request_spec =
      SoftLedgerAdapter.request_spec(
        request: request,
        token: access_token
      )

    # When
    {:ok, response} = SoftLedgerAdapter.create_location(request_spec)

    assert %CreateLocationResponse{} = response

    test_create_account(uuid, access_token, response._id)

    # clean_ up
    del_request = %DeleteLocationRequest{id: response._id}

    request_spec =
      SoftLedgerAdapter.request_spec(
        request: del_request,
        token: access_token
      )

    {:ok, message} = SoftLedgerAdapter.delete_location(request_spec)

    assert message == "successfully deleted"
  end

  def test_create_account(uuid, access_token, soft_ledger_location_id) do
    ledger_name = "LedgerName-#{uuid}"
    big_random_number = Enum.random(10..9_999_999)
    big_random_number_as_string = "#{big_random_number}"

    request = %CreateUpdateAccountRequest{
      LocationId: soft_ledger_location_id,
      name: ledger_name,
      naturalBalance: "debit",
      number: big_random_number_as_string,
      type: "Asset",
      subtype: "subtype not_set"
    }

    request_spec =
      SoftLedgerAdapter.request_spec(
        request: request,
        token: access_token
      )

    {:ok, response} = SoftLedgerAdapter.create_account(request_spec)

    assert %CreateUpdateAccountResponse{
             ICAccountId: nil,
             LocationId: ^soft_ledger_location_id,
             _id: soft_ledger_account_id,
             canDelete: true,
             description: "not_set",
             inactive: false,
             includeLocationChildren: true,
             name: ^ledger_name,
             naturalBalance: "debit",
             number: ^big_random_number_as_string,
             qbSubType: nil,
             revalue_fx: false,
             subtype: "subtype not_set",
             type: "Asset"
           } = response

    # When
    test_update_account(access_token, response)

    # clean_ up
    del_request = %DeleteAccountRequest{id: soft_ledger_account_id}

    request_spec =
      SoftLedgerAdapter.request_spec(
        request: del_request,
        token: access_token
      )

    {:ok, message} = SoftLedgerAdapter.delete_account(request_spec)

    assert message == "successfully deleted"
  end

  def test_update_account(access_token, create_update_response) do
    expected_description = "** UPDATED_DESCRIPTION **"
    soft_ledger_account_id = create_update_response._id
    ledger_name = create_update_response.name

    request = %CreateUpdateAccountRequest{
      LocationId: create_update_response."LocationId",
      name: create_update_response.name,
      naturalBalance: create_update_response.naturalBalance,
      number: create_update_response.number,
      type: create_update_response.type,
      subtype: create_update_response.subtype,
      description: expected_description
    }

    request_spec =
      SoftLedgerAdapter.request_spec(
        id: soft_ledger_account_id,
        request: request,
        token: access_token
      )

    {:ok, response} = SoftLedgerAdapter.update_account(request_spec)

    assert %CreateUpdateAccountResponse{
             ICAccountId: nil,
             LocationId: _location_id,
             _id: ^soft_ledger_account_id,
             canDelete: true,
             description: ^expected_description,
             inactive: false,
             includeLocationChildren: true,
             name: ^ledger_name,
             naturalBalance: "debit",
             number: _number,
             qbSubType: nil,
             revalue_fx: false,
             subtype: "subtype not_set",
             type: "Asset"
           } = response
  end
end
