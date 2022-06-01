defmodule AppCount.Admins.Utils.Passwords do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins.Admin
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def reset_password_request(email) do
    # TODO:SCHEMA confirm later client_schema not required
    from(
      a in Admin,
      where: a.email == ^email,
      select: {a.id, a.reset_pw},
      limit: 1
    )
    |> Repo.one()
    |> case do
      nil ->
        {:error, "Email address not found"}

      {_, false} ->
        {:error, "Password Reset not allowed"}

      {admin_id, true} ->
        token(admin_id)
        |> AppCountCom.Admins.admin_reset_password(email)
    end
  end

  def reset_password(token, password, confirmation) when password == confirmation do
    # TODO:SCHEMA remove dasmen later
    case verify(token) do
      {:ok, admin_id} ->
        Admins.update_admin(
          admin_id,
          ClientSchema.new(
            "dasmen",
            %{"password" => password}
          )
        )

      {:error, :invalid} ->
        {:error, "Invalid token"}

      {:error, :expired} ->
        {:error, "Expired token"}
    end
  end

  def reset_password(_, _, _), do: {:error, "Password does not match confirmation"}

  # FIX_DEPS  Better: move up stack
  def token(admin_id) do
    AppCountWeb.Token.token(admin_id)
  end

  def verify(token) do
    AppCountWeb.Token.verify(token)
  end
end
