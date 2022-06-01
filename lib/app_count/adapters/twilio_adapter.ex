defmodule AppCount.Adapters.TwilioAdapter do
  @moduledoc false
  use AppCount.ExternalService, :json_adapter
  alias AppCount.Adapters.Twilio.Credential
  alias AppCount.Adapters.TwilioExternalService
  alias AppCount.Core.Ports.RequestSpec
  alias AppCount.Core.SmsTopic
  alias AppCount.Core.PhoneNumber
  alias AppCount.Adapters.TwilioAdapterBehaviour
  alias AppCount.Adapters.TwilioAdapterBehaviour.CreateMessageResponse
  require Logger

  @behaviour TwilioAdapterBehaviour

  # ref: https://www.twilio.com/docs/api/errors/21211
  @twilio_invalid_to_phone_error 21211

  # ---------------------------------------------------------------------------------
  # public interface:
  # TwilioAdapter.send_sms()
  # ---------------------------------------------------------------------------------
  @impl TwilioAdapterBehaviour
  def send_sms(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &TwilioExternalService.safe_call/1
      ) do
    request_spec
    |> put_verb(:post)
    |> put_returning(CreateMessageResponse)
    |> put_url()
    |> put_data()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl TwilioAdapterBehaviour
  def request_spec(overrides) when is_list(overrides) do
    params =
      [adapter: __MODULE__]
      |> Keyword.merge(overrides)

    struct(AppCount.Core.Ports.RequestSpec, params)
  end

  # -------------------------------------------------------------

  defp put_data(%RequestSpec{request: request, returning: CreateMessageResponse} = request_spec) do
    request = %{request | data: create_message_request(request)}
    %{request_spec | request: request}
  end

  defp put_verb(%RequestSpec{} = request_spec, verb) do
    %{request_spec | verb: verb}
  end

  defp put_returning(%RequestSpec{} = request_spec, module) do
    %{request_spec | returning: module}
  end

  def put_url(%RequestSpec{url: url} = request_spec) do
    credentials = Credential.load()

    url = compose_url(credentials.sid, url)

    request_spec
    |> Map.put(:url, url)
  end

  def compose_url("", _) do
    message = "Twilio.Credential sid is blank"
    Logger.error(message)
    raise message
  end

  def compose_url(nil, _) do
    message = "Twilio.Credential sid is nil"
    Logger.error(message)
    raise message
  end

  def compose_url(sid, :not_set) do
    "https://api.twilio.com/2010-04-01/Accounts/#{sid}/Messages.json"
  end

  def compose_url(_sid, override_url) do
    override_url
  end

  def headers_with(%{sid: sid, token: token}) do
    full_token = "#{sid}:#{token}"
    headers_with_basic_auth(full_token)
  end

  # ---------------------------------------------------------------------------------
  # curl -X POST https://api.twilio.com/2010-04-01/Accounts/ACb00a5b065ca8143b493adc85b6ac272b/Messages.json --data-urlencode "Body=Hello World" --data-urlencode "From=+15005550006" --data-urlencode "To=+15005551111" -u ACb00a5b065ca8143b493adc85b6ac272b:5e026d4b7abf61162fe1a837e6d9d9bc
  # USE: HTTPoison.request/5
  def unsafe_call(%RequestSpec{request: request, url: url, verb: verb, returning: returning}) do
    credentials = Credential.load()

    headers = headers_with(credentials)

    enc_body = create_message_request(request)

    # HOWTO
    #
    # dump_curl(:post, url, enc_body, headers_with(token))
    # |> IO.inspect(
    #   label: " #{List.last(String.split(__ENV__.file, "/"))}:#{__ENV__.line} ",
    #   limit: :infinity,
    #   printable_limit: :infinity
    # )
    AppCount.Core.HTTPClient.request(convert_verb(verb), url, enc_body, headers)
    |> check_response_code(request)
    |> decode_into(returning)
  end

  def check_response_code({:ok, %HTTPoison.Response{status_code: 400, body: body}} = response, %{
        phone_to: phone_to
      }) do
    body_map =
      case Poison.decode(body, %{keys: :atoms}) do
        {:ok, body_map} -> body_map
        _ -> %{code: 0}
      end

    if body_map[:code] == @twilio_invalid_to_phone_error do
      SmsTopic.invalid_phone_number(%{phone: phone_to}, __MODULE__)
    end

    response
  end

  def check_response_code(response, _request) do
    response
  end

  def create_message_request(
        %{message: message, phone_to: phone_to, phone_from: property_phone_from},
        credentials \\ Credential.load()
      ) do
    property_phone_from = PhoneNumber.new(property_phone_from)

    phone_from =
      if PhoneNumber.valid?(property_phone_from) do
        property_phone_from |> PhoneNumber.dial_string()
      else
        default_site_wide_from_number(credentials)
      end

    %{"To" => phone_to, "From" => phone_from, "Body" => message} |> URI.encode_query()
  end

  def default_site_wide_from_number(credentials) do
    phone_from = PhoneNumber.new(credentials.phone_from)

    if PhoneNumber.valid?(phone_from) do
      PhoneNumber.dial_string(phone_from)
    else
      error = "Invalid Site Wide FROM Phone Number Check: Twilio.Credential"
      Logger.error(error)
      "Invalid from_phone. Check: Twilio.Credential"
    end
  end

  def convert_verb(verb) do
    verb
    |> Atom.to_string()
    |> String.upcase()
  end
end
