defmodule AppCountCom do
  def view do
    quote do
      use Phoenix.View, root: "lib/app_count_com/templates", namespace: AppCountCom

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      alias AppCountWeb.Router.Helpers, as: Routes
      import AppCountWeb.ErrorHelpers
      import AppCountWeb.Gettext
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
