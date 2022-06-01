defmodule AppCount.Adapters.SoftLedgerAdapter do
  @moduledoc """
  Connects to the outside world using SoftLedger
  * Creates and configures a RequestSpec
  * passes the request_spec to SoftLedgerExternalService
  """
  use AppCount.ExternalService, :json_adapter
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses
  @behaviour SoftLedgerBehaviour
  alias AppCount.Core.Ports.RequestSpec

  alias AppCount.Adapters.SoftLedgerAdapter.Service
  alias AppCount.Adapters.SoftLedgerExternalService, as: Service
  @oauth_url "https://auth.accounting-auth.com/oauth/token"
  @base_url AppCount.Adapters.SoftLedger.Config.load().url

  @impl SoftLedgerBehaviour
  def fetch_token(safe_call_fn \\ &Service.safe_call/1) do
    %RequestSpec{url: @oauth_url, verb: :oauth, returning: OAuthResponse, adapter: __MODULE__}
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl SoftLedgerBehaviour
  def request_spec(overrides) when is_list(overrides) do
    params =
      [adapter: __MODULE__]
      |> Keyword.merge(overrides)

    struct(AppCount.Core.Ports.RequestSpec, params)
  end

  # ===================================================   Cash Receipt
  @impl SoftLedgerBehaviour
  def create_cash_receipt(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  # ===================================================   Invoice
  @impl SoftLedgerBehaviour
  def create_invoice(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl SoftLedgerBehaviour
  def issue_invoice(
        %RequestSpec{request: %{id: softledger_id}} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec(softledger_id)
    |> safe_call_fn.()
    |> return_ok_error()
  end

  # ===================================================   Customer
  @impl SoftLedgerBehaviour
  def create_customer(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl SoftLedgerBehaviour
  def delete_customer(
        %RequestSpec{request: %{id: id}} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec(id)
    |> safe_call_fn.()
    |> return_ok_error()
  end

  # ===================================================   Location
  @impl SoftLedgerBehaviour
  def create_location(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl SoftLedgerBehaviour
  def delete_location(
        %RequestSpec{request: %{id: id}} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec(id)
    |> safe_call_fn.()
    |> return_ok_error()
  end

  # ===================================================   Account
  @impl SoftLedgerBehaviour
  def create_account(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl SoftLedgerBehaviour
  def update_account(
        %RequestSpec{id: soft_ledger_account_id} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec(soft_ledger_account_id)
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl SoftLedgerBehaviour
  # TODO change to use request_spec.id rather than request.id
  def delete_account(
        %RequestSpec{request: %{id: soft_ledger_account_id}} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec(soft_ledger_account_id)
    |> safe_call_fn.()
    |> return_ok_error()
  end

  # ===================================================   Payment
  @impl SoftLedgerBehaviour
  def create_payment(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  # ===================================================   Journal
  @impl SoftLedgerBehaviour
  def create_journal(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl SoftLedgerBehaviour
  def get_journal(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl SoftLedgerBehaviour
  def delete_journal(
        %RequestSpec{request: %{id: id}} = request_spec,
        safe_call_fn \\ &Service.safe_call/1
      ) do
    request_spec
    |> load_req_to_spec(id)
    |> safe_call_fn.()
    |> return_ok_error()
  end

  # ----------- UNSAFE CALLBACKS From SoftLedgerExternalService --------------------------------
  def unsafe_call(
        %RequestSpec{token: token, request: _request, returning: returning, url: url, verb: :get} =
          _request_spec
      )
      when is_binary(token) do
    header = headers_with_bearer(token)

    url
    |> HTTPoison.get(header)
    |> decode_into(returning)
  end

  def unsafe_call(
        %RequestSpec{token: token, request: request, returning: returning, url: url, verb: :post} =
          _request_spec
      )
      when is_binary(token) do
    enc_body = encode_request(request)
    header = headers_with_bearer(token)

    url
    |> HTTPoison.post(enc_body, header)
    |> decode_into(returning)
  end

  def unsafe_call(%RequestSpec{
        token: token,
        request: request,
        returning: :no_return_data,
        url: url,
        verb: :put
      })
      when is_binary(token) do
    enc_body = encode_request(request)

    url
    |> HTTPoison.put(enc_body, headers_with_bearer(token))
    |> check_status_code(StatusResponse)
  end

  def unsafe_call(
        %RequestSpec{token: token, request: request, returning: returning, url: url, verb: :put} =
          _request_spec
      )
      when is_binary(token) do
    enc_body = encode_request(request)

    # HOWTO
    #
    # dump_curl(:post, url, enc_body, headers_with_bearer(token))
    # |> IO.inspect(
    #   label: " #{List.last(String.split(__ENV__.file, "/"))}:#{__ENV__.line} ",
    #   limit: :infinity,
    #   printable_limit: :infinity
    # )

    url
    |> HTTPoison.put(enc_body, headers_with_bearer(token))
    |> decode_into(returning)
  end

  def unsafe_call(%RequestSpec{token: token, returning: returning, url: url, verb: :delete}) do
    url
    |> HTTPoison.delete(headers_with_bearer(token))
    |> decode_into(returning)
  end

  def unsafe_call(%RequestSpec{url: url, returning: returning, verb: :oauth} = _request_spec) do
    # Different Logic, because here we get the initial OAuth Token
    oauth_headers = [{"Accept", "application/json"}, {"Content-Type", "application/json"}]

    oauth_creds_body =
      AppCount.Adapters.SoftLedger.Credential.load()
      |> Map.from_struct()
      |> Poison.encode!()

    HTTPoison.post(url, oauth_creds_body, oauth_headers)
    |> decode_into(returning)
  end

  def encode_request(request) do
    request
    |> Map.from_struct()
    |> Poison.encode!()
  end

  # -- load_req_to_spec ---------------------------------------------
  def load_req_to_spec(request_spec, id \\ nil)

  def load_req_to_spec(%RequestSpec{request: :not_set}, _id) do
    raise "Error SoftLedgerAdapter.load_req_to_spec(), request must be set"
  end

  # TODO change functions receiving a request_spec to get this data from the request directly, not in the copied fields below.
  # for example request_spec.request.verb, and request_spec.request.returning
  # after that remove these fields from the request_spec.
  def load_req_to_spec(%RequestSpec{url: :not_set, request: request} = request_spec, id) do
    request_module = request.__struct__
    path = request_module.path(@base_url, id)
    returning = request_module.returning()
    verb = request_module.verb()

    %{request_spec | returning: returning, url: path, verb: verb}
  end
end
