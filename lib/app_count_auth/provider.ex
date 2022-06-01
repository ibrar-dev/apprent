defmodule AppCountAuth.Provider do
  def authorizer_for(controller, action) do
    module =
      controller
      |> Module.split()
      |> List.replace_at(0, "AppCountAuth")
      |> Module.concat()

    mod =
      case Code.ensure_compiled(module) do
        {:module, mod} -> mod
        _ -> AppCountAuth.OpenController
      end

    if function_exported?(mod, action, 2) do
      mod
    else
      false
    end
  end
end
