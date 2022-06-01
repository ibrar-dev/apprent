defmodule AppCountAuth.Utils do
  alias AppCountAuth.Users.Admin

  def module_enabled?(%{} = user, feature_name) do
    if Map.get(user.features, feature_name) do
      {:ok, :module_enabled}
    else
      {:error, :module_disabled}
    end
  end

  def has_permission?(%Admin{roles: %MapSet{map: %{"Super Admin" => _}}}, _property_id), do: true

  def has_permission?(%Admin{} = admin, property_id) do
    if Enum.member?(admin.property_ids, property_id) do
      {:ok, :has_permission}
    else
      {:error, :no_property_permission}
    end
  end

  def has_role?(%Admin{roles: %MapSet{map: %{"Super Admin" => _}}}, _property_id), do: true

  def has_role?(%Admin{} = admin, role) do
    if MapSet.member?(admin.roles, role) do
      {:ok, :has_role}
    else
      {:error, :invalid_roles}
    end
  end

  def is_super_admin?(%Admin{roles: %MapSet{map: %{"Super Admin" => _}}}), do: {:ok, :has_role}
  def is_super_admin?(_), do: {:error, :invalid_roles}
end
