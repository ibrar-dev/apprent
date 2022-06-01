defmodule AppCountWeb.Region.RegionLive do
  use AppCountWeb, :live_view

  def mount(_params, session, socket) do
    assign_user(session, socket)
    # |> case do
    #   {:ok, new_socket} -> {:ok, assign(socket, page_title: "View Regions")}
    #   {:error, _} -> {:ok, redirect(socket, to: "/")}
    # end
  end

  ## -- Add in current user and roles to assign -- ##
  def assign_user(%{"admin_token" => token}, socket) do
    with {:ok, %AppCount.Admins.Admin{} = admin, _new_token} <-
           AppCount.Admins.Auth.Tokens.verify(token) do
      {:ok, assign(socket, admin: admin, roles: admin.roles)}
    else
      _ ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  def assign_user(_session, _socket), do: {:error, :bad_token}

  ## -- Validate role -- ##
  def validate_role(%{assign: %{roles: roles}} = socket, role) do
    case Enum.member?(roles, role) do
      true -> {:ok, socket}
      _ -> {:ok, redirect(socket, to: "/")}
    end
  end
end
