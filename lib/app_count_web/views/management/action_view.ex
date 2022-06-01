defmodule AppCountWeb.Management.ActionView do
  use AppCountWeb, :view

  def permission_type_options() do
    [
      [value: "read-write", key: "Read/Write"],
      [value: "yes-no", key: "Yes/No"]
    ]
  end

  def module_options(modules) do
    Enum.map(modules, fn module ->
      [key: module.name, value: module.id]
    end)
  end
end
