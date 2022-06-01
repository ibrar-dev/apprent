defmodule AppCountAuth.AuthChecks do
  @moduledoc """
    Defines one function auth_checks/2, which takes a user struct and a permissions keyword list.
    Allows us to express authorization requirements declaratively, so

      - auth_checks(user, super_admin: true, module_enabled: :maintenance)

    will check if the user is a super admin and if the maintenance module is enabled for it's client.
    
    Checks are processed in a specific order determined by the @valid_checks attribute, this is intentional

    Checks can also be doubled up, so this:

      - auth_checks(user, super_admin: true, module_enabled: :maintenance, module_enabled: :accounting)
    
    will ensure that both maintenance and accounting are enabled.

    The :custom option allows us to pass in a function that takes one argument(the user struct). The function
    must be passed inside a tuple with the error message to return in case the authorization fails.

      # inside an Authorizer:
      def index(user, params) do
        func = fn(user) -> length(user.property_ids) > 3 end
        auth_checks(user, custom: {func, "Admin must have permissions to at least 3 properties"})
      end
  """
  @valid_checks [:module_enabled, :super_admin, :role_auth, :property_access, :custom]
  @ok_return {:ok, :authorized}
  import AppCountAuth.Utils

  def auth_checks(user, auth_requirements) do
    auth_requirements
    |> ordered_checks
    |> Enum.reduce_while(@ok_return, &do_check(user, &1, &2))
  end

  defp do_check(_user, {_check, nil}, response), do: {:cont, response}

  defp do_check(user, {check, value}, {:ok, _} = response) when check in @valid_checks do
    case do_auth_check(user, check, value) do
      {:ok, _} ->
        {:cont, response}

      e ->
        {:halt, e}
    end
  end

  defp do_auth_check(user, :module_enabled, module) do
    module_enabled?(user, module)
  end

  defp do_auth_check(user, :super_admin, true) do
    is_super_admin?(user)
  end

  defp do_auth_check(user, :property_access, property_id) do
    has_permission?(user, property_id)
  end

  defp do_auth_check(user, :role_auth, role_list) do
    has_role?(user, role_list)
  end

  defp do_auth_check(user, :custom, {func, on_error})
       when is_function(func) and is_binary(on_error) do
    if func.(user) do
      {:ok, :authorized}
    else
      {:error, on_error}
    end
  end

  defp ordered_checks(auth_requirements) do
    key = Enum.with_index(@valid_checks)

    Enum.sort_by(
      auth_requirements,
      fn {check, _} ->
        key[check]
      end,
      :asc
    )
  end
end
