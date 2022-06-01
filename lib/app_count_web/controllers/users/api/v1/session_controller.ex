defmodule AppCountWeb.Users.API.V1.SessionController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts.Utils.Accounts
  alias AppCount.Accounts.Utils.Logins
  alias AppCount.Accounts.Account
  alias AppCount.Public.Auth

  def create(conn, %{"username" => username, "password" => password} = params) do
    with {:ok, %{account_id: account_id} = user} <- Auth.authenticate_user(username, password),
         {:ok, _user} <- active_property(user),
         %{} = metadata <- extract_login_metadata(params),
         language <- extract_language(params),
         {:ok, _login} <- create_login(metadata, user),
         token <- AppCountWeb.Token.token(user),
         {:ok, %Account{} = account} <- Accounts.set_language(account_id, language) do
      response_data = %{
        token: token,
        features: AppCount.env(:features),
        preferred_language: account.preferred_language
      }

      json(conn, response_data)
    else
      {:error, "No longer under AppRent management"} ->
        conn
        |> put_status(401)
        |> json(%{error: "No longer under AppRent management"})

      _ ->
        conn
        |> put_status(401)
        |> json(%{error: "Invalid Login"})
    end
  end

  defp create_login(metadata, user) do
    Logins.create_login(%{
      account_id: user.account_id,
      type: "app",
      login_metadata: metadata
    })
  end

  def show(conn, %{"username" => email}) do
    case Accounts.check_if_user_registered(email) do
      nil -> json(conn, false)
      _ -> json(conn, true)
    end
  end

  defp active_property(%{active: true} = user), do: {:ok, user}

  defp active_property(_user), do: {:error, "No longer under AppRent management"}

  defp extract_login_metadata(%{"login_metadata" => login_metadata})
       when is_map(login_metadata) do
    login_metadata
  end

  defp extract_login_metadata(_params) do
    %{}
  end

  defp extract_language(%{"language" => language}) do
    case language do
      "en" -> "english"
      "es" -> "spanish"
      _ -> "english"
    end
  end

  defp extract_language(_) do
    "english"
  end
end
