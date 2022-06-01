defmodule AppCountWeb.Users.StaticPageController do
  use AppCountWeb.Users, :controller
  alias AppCount.Adapters.ZendeskAdapterBehaviour.CreateTicketRequest
  alias AppCount.Adapters.ZendeskAdapterBehaviour.CreateTicketResponse
  alias AppCount.Adapters.ZendeskAdapter
  require Logger

  @subject "AppRent Support Form"
  @tags ["New AppRent Support"]
  @custom_field_id 360_039_177_672

  def about(conn, _params) do
    render(conn, "about.html", layout: false)
  end

  def privacy(conn, _params) do
    render(conn, "privacy.html", layout: false)
  end

  def contact(conn, _params) do
    render(conn, "contact.html", layout: false)
  end

  def accept(conn, _params) do
    render(conn, "accept.html", layout: false)
  end

  # Pretty much all of this logic should be moved elsewhere.
  def ticket(conn, %{"message" => params}) do
    base =
      "From #{params["name"]}:\n\n\n#{params["message"]}\n\nEmail: #{params["email"]}\nPhone: #{
        params["phone"]
      }"

    user = get_user(conn)

    message =
      case user do
        nil ->
          base

        u ->
          "#{base}\n\nResident: #{u.name}\n\nAppRent Profile: #{
            AppCount.namespaced_url('administration')
          }/tenants/#{u.id}"
      end

    request =
      CreateTicketRequest.new(
        subject: @subject,
        description: message,
        tags: @tags,
        custom_fields: extra_options(user)
      )

    request_spec = ZendeskAdapter.request_spec(request: request)

    ZendeskAdapter.create_ticket(request_spec)
    |> case do
      {:ok, %CreateTicketResponse{}} ->
        json(conn, %{})

      _ ->
        conn
        |> put_status(422)
        |> json(%{error: "Error submitting request"})
    end
  end

  defp extra_options(nil), do: %{}

  defp extra_options(user) do
    %{
      custom_fields: [
        %{
          id: @custom_field_id,
          value: "#{AppCount.namespaced_url('administration')}/tenants/#{user.id}"
        }
      ],
      external_id: user.id
    }
  end

  defp get_user(conn) do
    with token when is_binary(token) <- get_session(conn, :user_token),
         {:ok, %{} = u, _} <- AppCount.Accounts.verify_token(token) do
      u
    else
      _ -> nil
    end
  end
end
