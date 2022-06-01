defmodule AppCount.Admins.Auth.Authentication do
  import Bcrypt
  import Ecto.Query
  alias AppCount.Admins.Admin
  alias AppCount.Repo

  @authenticable_params ["email", "username"]

  def crypt_password(password) do
    hash_pwd_salt(password)
  end

  def authenticate(password, %{} = params) do
    authenticate(password, Map.to_list(params))
  end

  def authenticate(password, [{key, value}]) when key in @authenticable_params do
    authenticate(password, [{String.to_atom(key), value}])
  end

  def authenticate(password, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    with %Admin{} = admin <-
           from(from(admin in Admin, where: ^params, where: admin.active == true, limit: 1))
           |> Repo.one(prefix: client_schema),
         true <- verify_pass(password, admin.password_hash) do
      {:ok, admin}
    else
      nil -> {:error, :no_user}
      false -> {:error, :password_invalid}
    end
  end
end
