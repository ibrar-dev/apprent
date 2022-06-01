defmodule AppCount.Adapters.ZendeskAdapter do
  use AppCount.ExternalService, :json_adapter
  alias AppCount.Adapters.ZendeskAdapterBehaviour
  alias AppCount.Adapters.Zendesk.Credential
  alias AppCount.Adapters.ZendeskExternalService
  alias AppCount.Adapters.ZendeskAdapterBehaviour.CreateTicketResponse
  alias AppCount.Core.Ports.RequestSpec
  require Logger

  @content_type "application/json"

  @behaviour ZendeskAdapterBehaviour

  # ---------------------------------------------------------------------------------
  # public interface:
  # ZendeskAdapter.create_ticket()
  # ---------------------------------------------------------------------------------
  @impl ZendeskAdapterBehaviour
  def create_ticket(
        %RequestSpec{} = request_spec,
        safe_call_fn \\ &ZendeskExternalService.safe_call/1
      ) do
    request_spec
    |> put_verb(:post)
    |> put_returning(CreateTicketResponse)
    |> put_url()
    |> put_data()
    |> safe_call_fn.()
    |> return_ok_error()
  end

  @impl ZendeskAdapterBehaviour
  def request_spec(overrides) when is_list(overrides) do
    params =
      [adapter: __MODULE__]
      |> Keyword.merge(overrides)

    struct(AppCount.Core.Ports.RequestSpec, params)
  end

  defp put_verb(%RequestSpec{} = request_spec, verb) do
    %{request_spec | verb: verb}
  end

  defp put_returning(%RequestSpec{} = request_spec, module) do
    %{request_spec | returning: module}
  end

  def put_url(%RequestSpec{url: url, returning: CreateTicketResponse} = request_spec) do
    credentials = Credential.load()

    url = compose_url(credentials, url)

    %{request_spec | url: url}
  end

  # Build body of request here.
  def put_data(%RequestSpec{request: request, returning: CreateTicketResponse} = request_spec) do
    request =
      %{
        ticket: %{
          comment: %{
            body: request.description
          },
          description: request.description,
          subject: request.subject,
          tags: request.tags,
          custom_fields: request.custom_fields
        }
      }
      |> Poison.encode!()

    %{request_spec | request: request}
  end

  def compose_url(nil, _) do
    message = "Zendesk.Credentials is blank"
    Logger.error(message)
    raise message
  end

  def compose_url(%{api_token: nil}, _) do
    message = "Zendesk.Credentials api_token is blank"
    Logger.error(message)
    raise message
  end

  def compose_url(%{subdomain: nil}, _) do
    message = "Zendesk.Credentials subdomain is blank"
    Logger.error(message)
    raise message
  end

  def compose_url(%{user: nil}, _) do
    message = "Zendesk.Credentials user is blank"
    Logger.error(message)
    raise message
  end

  def compose_url(%{subdomain: subdomain}, :not_set) do
    "https://#{subdomain}.zendesk.com/api/v2/tickets.json"
  end

  def compose_url(_creds, override_url) do
    override_url
  end

  def unsafe_call(%RequestSpec{request: request, url: url, verb: verb, returning: returning}) do
    credentials = Credential.load()

    headers = basic_auth_headers(credentials)

    HTTPoison.request(convert_verb(verb), url, request, headers)
    |> decode_into(returning)
    |> IO.inspect(label: " #{List.last(String.split(__ENV__.file, "/"))}:#{__ENV__.line} ")
  end

  def basic_auth_headers(%{user: user, api_token: api_token}) do
    [
      "Content-Type": @content_type,
      Authorization: "Basic #{base64token(user, api_token)}"
    ]
  end

  def base64token(user, api_token) do
    "#{user}/token:#{api_token}"
    |> Base.encode64()
  end

  def convert_verb(verb) do
    verb
    |> Atom.to_string()
    |> String.upcase()
  end
end
