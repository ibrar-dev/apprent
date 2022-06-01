defmodule AppCountWeb do
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

  def public_controller do
    quote do
      use Phoenix.Controller, namespace: AppCountWeb
      import Plug.Conn
      alias AppCountWeb.Router.Helpers, as: Routes
      import AppCountWeb.Gettext
      import AppCount.StructSerialize
      import AppCountWeb.ControllerHelpers
      import Phoenix.LiveView.Controller
      import AppCountWeb.BoundaryHelpers
    end
  end

  def controller do
    quote do
      import AppCountWeb.ControllerHelpers
      use Phoenix.Controller, namespace: AppCountWeb
      import Plug.Conn
      alias AppCountWeb.Router.Helpers, as: Routes
      import AppCountWeb.Gettext
      import AppCount.StructSerialize
      import AppCountWeb.Authorize
      import Phoenix.LiveView.Controller
      import AppCountWeb.BoundaryHelpers
      plug AppCountWeb.AuthorizationPlug
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/app_count_web/templates",
        namespace: AppCountWeb,
        pattern: "**/*"

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      alias AppCountWeb.Router.Helpers, as: Routes
      import AppCountWeb.ErrorHelpers
      import AppCountWeb.Gettext
      import Phoenix.LiveView.Helpers
      import AppCountWeb.LiveHelpers
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {AppCountWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import AppCountWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers
      import AppCountWeb.LiveHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import AppCountWeb.ErrorHelpers
      import AppCountWeb.Gettext
      alias AppCountWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
