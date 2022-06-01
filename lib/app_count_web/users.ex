defmodule AppCountWeb.Users do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use AppCountWeb, :controller
      use AppCountWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: AppCountWeb.Users
      import Plug.Conn
      alias AppCountWeb.Router.Helpers, as: Routes
      import AppCountWeb.Gettext
      import AppCount.StructSerialize
      import AppCountWeb.ControllerHelpers
      import AppCountWeb.BoundaryHelpers
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/app_count_web/templates/users",
        namespace: AppCountWeb.Users

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      alias AppCountWeb.Router.Helpers, as: Routes
      import AppCountWeb.ErrorHelpers
      import AppCountWeb.Gettext
      use AppCountWeb.ViewHelpers
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import AppCountWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
