defmodule AppCountWeb.NavBarComponent do
  use AppCountWeb, :live_component

  # Requires a page_title in assigns
  def render(assigns) do
    ~L"""
      <header class="app-header navbar">
        <button class="navbar-toggler sidebar-toggler d-sm-block d-pro-none" type="button">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div style="background-color:#5dbd77">
          <div style="background-color:#3a3b42; border-radius: 0px 0px 0px 29px;">
          <a class="navbar-brand nav-ar">
            <img src="<%= Routes.static_path(@socket, "/images/appRent_logo.png") %>" class="h-100"/>
          </a>
          </div>
        </div>
        <div>
          <div class="navbar-nav">
            <div class="page-title px-4">
              <h6 style="color: #888a96"class="m-0"><%= @page_title %></h6>
            </div>
          </div>
        </div>
        <div class="d-flex ml-auto h-100">
        </div>
      </header>
    """
  end
end
