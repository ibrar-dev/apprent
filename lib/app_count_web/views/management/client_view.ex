defmodule AppCountWeb.Management.ClientView do
  use AppCountWeb, :view

  def with_parsed_features(changeset) do
    applied = Ecto.Changeset.get_field(changeset, :client_modules)
    Ecto.Changeset.put_assoc(changeset, :client_modules, applied)
  end

  def tag_safe(feature_name) do
    String.replace(feature_name, " ", "")
    |> Macro.underscore()
  end

  def readable(feature_name) do
    Macro.camelize(feature_name)
    |> String.replace(~r"(.)([A-Z])", "\\1 \\2")
  end
end
