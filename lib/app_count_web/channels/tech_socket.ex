defmodule AppCountWeb.TechSocket do
  use Phoenix.Socket
  alias AppCount.Maintenance.Tech

  channel("tech_mobile", AppCountWeb.TechChannel)

  def connect(%{"cert" => cert}, socket) do
    case AppCount.Maintenance.authenticate_tech(cert) do
      %Tech{} = tech -> {:ok, assign(socket, :tech, tech)}
      nil -> :error
    end
  end

  def id(_socket), do: nil
end
