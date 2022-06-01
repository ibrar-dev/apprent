defmodule AppCount.Admins.Auth.Tokens do
  alias AppCount.Admins.Admin

  @spec verify(String.t()) :: {:ok, %Admin{}, String.t()} | {:error, :bad_token}
  def verify(token) do
    # FIX_DEPS

    case AppCountWeb.Token.verify(token) do
      {:ok, user} -> {:ok, user, AppCountWeb.Token.token(user)}
      _ -> {:error, :bad_token}
    end
  end
end
