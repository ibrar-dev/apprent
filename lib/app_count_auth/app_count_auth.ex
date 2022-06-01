defmodule AppCountAuth do
  def module do
    quote do
      use AppCountAuth.ModuleOld
    end
  end

  def request do
    quote do
      use AppCountAuth.Base
      import AppCountAuth.AuthChecks
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
