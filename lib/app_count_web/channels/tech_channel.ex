defmodule AppCountWeb.TechChannel do
  use AppCountWeb, :channel
  alias AppCountWeb.TechPresence, as: Presence
  alias AppCount.Maintenance
  alias AppCount.Materials
  alias AppCount.Core.ClientSchema
  require Logger

  def join(_topic, _message, socket) do
    current_process = self()
    send(current_process, :after_join)
    send(current_process, :manage)
    tech_id = socket.assigns.tech.id
    {:ok, %{id: tech_id}, socket}
  end

  # UNUSED
  def send_clock_data(%{client_schema: client_schema, tech_id: tech_id, end_ts: end_ts}) do
    String.to_atom("tc::#{client_schema}-#{tech_id}")
    |> Process.whereis()
    |> case do
      nil -> nil
      pid -> send(pid, %{send: {"CLOCK", %{status: !end_ts}}})
    end
  end

  def send_tech_info(%ClientSchema{name: client_schema, attrs: tech_id} = schema) do
    String.to_atom("tc::#{client_schema}-#{tech_id}")
    |> Process.whereis()
    |> case do
      nil -> nil
      pid -> send(pid, %{send: {"PROFILE", %{info: Maintenance.tech_info(schema)}}})
    end
  end

  def send_tech_notification(%ClientSchema{name: client_schema, attrs: tech_id}, title, body) do
    String.to_atom("tc::#{client_schema}-#{tech_id}")
    |> Process.whereis()
    |> case do
      nil -> nil
      pid -> send(pid, %{send: {"NOTIFICATION", %{title: title, body: body}}})
    end
  end

  def send_tech_data(%ClientSchema{name: client_schema, attrs: tech_id} = schema) do
    String.to_atom("tc::#{client_schema}-#{tech_id}")
    |> Process.whereis()
    |> case do
      nil -> nil
      pid -> send(pid, %{send: {"DATA", Maintenance.tech_data(schema)}})
    end
  end

  def send_order_data(%ClientSchema{name: client_schema, attrs: tech_id} = schema, order_id) do
    String.to_atom("tc::#{client_schema}-#{tech_id}")
    |> Process.whereis()
    |> case do
      nil -> nil
      pid -> send(pid, %{send: {"ORDER_DATA", Maintenance.tech_order_data(schema, order_id)}})
    end
  end

  # UNUSED
  def send_toolbox(%ClientSchema{name: client_schema, attrs: tech_id} = schema) do
    String.to_atom("tc::#{client_schema}-#{tech_id}")
    |> Process.whereis()
    |> case do
      nil -> nil
      pid -> send(pid, %{send: {"TOOLBOX", %{toolbox: Materials.list_items_in_toolbox(schema)}}})
    end
  end

  def handle_info(%{send: {msg, payload}}, socket) do
    push(socket, msg, payload)
    {:noreply, socket}
  end

  def handle_info(:manage, socket) do
    tech_id = socket.assigns.tech.id
    client_schema = socket.assigns.tech.__meta__.prefix
    process_name = String.to_atom("tc::#{client_schema}-#{tech_id}")

    unless Process.whereis(process_name) do
      Process.register(self(), process_name)
      monitor(process_name)
    end

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    tech_id = with_schema(socket.assigns.tech, socket.assigns.tech.id)
    Maintenance.log_on(tech_id)

    {:ok, _} =
      Presence.track(
        self(),
        "tech_admin",
        "#{tech_id.name}-#{tech_id.attrs}",
        %{online_at: inspect(System.system_time(:second))}
      )

    push(socket, "DATA", Maintenance.tech_data(tech_id))
    {:noreply, socket}
  end

  def handle_info(unexpected, socket) do
    Logger.error("Unexpected handle_info received by TechChannel: #{inspect(unexpected)}")
    {:noreply, socket}
  end

  def handle_in("FETCH_ORDER", %{"id" => order_id}, socket) do
    order_data =
      with_schema(socket.assigns.tech, socket.assigns.tech.id)
      |> Maintenance.tech_order_data(order_id)

    push(socket, "ORDER_DATA", order_data)
    {:noreply, socket}
  end

  def handle_in("GET_PROFILE", _, socket) do
    with_schema(socket.assigns.tech, socket.assigns.tech.id)
    |> send_tech_info()

    {:noreply, socket}
  end

  # UNUSED
  def handle_in("UPDATE_INVENTORY", params, socket) do
    with_schema(socket.assigns.tech, params["inventory"])
    |> Materials.attach_items_to_assignment()

    with_schema(socket.assigns.tech, socket.assigns.tech.id)
    |> send_toolbox()

    {:noreply, socket}
  end

  def handle_in("UPDATE_PROFILE", params, socket) do
    tech_id = with_schema(socket.assigns.tech, socket.assigns.tech.id)
    Maintenance.update_tech(tech_id, params)
    send_tech_info(tech_id)
    {:noreply, socket}
  end

  def handle_in("NOTIFICATION_TOKEN", params, socket) do
    with_schema(socket.assigns.tech, socket.assigns.tech.id)
    |> Maintenance.update_tech(params)

    {:reply, {:ok, nil}, socket}
  end

  # UNUSED
  def handle_in("GET_CLOCK_STATUS", _, socket) do
    with_schema(socket.assigns.tech, socket.assigns.tech.id)
    |> Maintenance.get_tech_status()
    |> Map.put(:client_schema, socket.assigns.tech.__meta__.prefix)
    |> send_clock_data

    {:noreply, socket}
  end

  def handle_in("COORDINATES", msg, socket) do
    coords = %{lat: msg["lat"], lng: msg["lng"]}

    with_schema(socket.assigns.tech, socket.assigns.tech.id)
    |> Maintenance.set_tech_coords(coords)

    {:noreply, socket}
  end

  def handle_in("CONFIRM", %{"id" => id}, socket) do
    with_schema(socket.assigns.tech, id)
    |> Maintenance.accept_assignment()

    {:reply, {:ok, nil}, socket}
  end

  # UNUSED
  def handle_in("GET_TOOLBOX", _, socket) do
    with_schema(socket.assigns.tech, socket.assigns.tech.id)
    |> send_toolbox()

    {:reply, {:ok, nil}, socket}
  end

  def handle_in("COMPLETE", %{"id" => id, "details" => d}, socket) do
    # EVENT:  publish event from here
    # possible errors are ignored.  Could be:   {:error, :bad_params}
    with_schema(socket.assigns.tech, id)
    |> Maintenance.complete_assignment(d, socket.assigns.tech.id)

    {:reply, {:ok, nil}, socket}
  end

  def handle_in("REJECT", msg, socket) do
    # EVENT:  publish event from here
    assignment_id = msg["id"]
    reason = msg["reason"]

    with_schema(socket.assigns.tech, assignment_id)
    |> Maintenance.reject_assignment(reason)

    {:reply, {:ok, nil}, socket}
  end

  def handle_in("NOTE", %{"id" => assignment_id} = msg, socket) do
    schema = with_schema(socket.assigns.tech, assignment_id)
    Maintenance.create_tech_note(schema, msg)

    %{order_id: order_id} =
      AppCount.Repo.get(AppCount.Maintenance.Assignment, assignment_id, prefix: schema.name)

    order_data =
      with_schema(socket.assigns.tech, socket.assigns.tech.id)
      |> Maintenance.tech_order_data(order_id)

    push(socket, "ORDER_DATA", order_data)
    {:noreply, socket}
  end

  def handle_in("SCAN", %{"id" => assignment_id, "ref" => ref}, socket) do
    schema = with_schema(socket.assigns.tech, assignment_id)
    resp = Materials.get_ref(schema, ref) || %{}
    push(socket, "SCAN", resp)
    {:noreply, socket}
  end

  # UNUSED
  def handle_in("ATTACH_ITEMS", params, socket) do
    with_schema(socket.assigns.tech, params)
    |> Materials.attach_items_to_assignment()

    schema = with_schema(socket.assigns.tech, socket.assigns.tech.id)
    push(socket, "TOOLBOX", %{toolbox: Materials.list_items_in_toolbox(schema)})
    {:noreply, socket}
  end

  # UNUSED
  def handle_in("REMOVE_MAT", %{"id" => assignment_id, "material" => material}, socket) do
    # EVENT:  publish event from here
    with_schema(socket.assigns.tech, assignment_id)
    |> Maintenance.remove_material(material)

    schema = with_schema(socket.assigns.tech, socket.assigns.tech.id)
    push(socket, "DATA", Maintenance.tech_data(schema))
    {:noreply, socket}
  end

  def handle_in("NO_ACCESS", %{"order_id" => id, "assignment_id" => assignment_id}, socket) do
    # EVENT:  publish event from here
    schema = with_schema(socket.assigns.tech, socket.assigns.tech.id)
    Maintenance.no_access(schema, id)

    with_schema(socket.assigns.tech, assignment_id)
    |> Maintenance.pause_assignment()

    push(socket, "DATA", Maintenance.tech_data(schema))
    {:noreply, socket}
  end

  def handle_in("PAUSE", %{"id" => assignment_id}, socket) do
    # EVENT:  publish event from here
    with_schema(socket.assigns.tech, assignment_id)
    |> Maintenance.pause_assignment()

    schema = with_schema(socket.assigns.tech, socket.assigns.tech.id)
    push(socket, "DATA", Maintenance.tech_data(schema))
    {:noreply, socket}
  end

  def handle_in("RESUME", %{"id" => assignment_id}, socket) do
    # EVENT:  publish event from here
    with_schema(socket.assigns.tech, assignment_id)
    |> Maintenance.resume_assignment()

    data = with_schema(socket.assigns.tech, socket.assigns.tech.id)
    push(socket, "DATA", Maintenance.tech_data(data))
    {:noreply, socket}
  end

  def handle_in("NOTIFY", %{"id" => assignment_id, "time" => time}, socket) do
    # EVENT:  publish event from here
    with_schema(socket.assigns.tech, assignment_id)
    |> Maintenance.tech_dispatched(time)

    {:reply, {:ok, nil}, socket}
  end

  # UNUSED
  def handle_in("CLOCK", params, socket) do
    with_schema(socket.assigns.tech, socket.assigns.tech.id)
    |> Maintenance.clock(params)

    {:reply, {:ok, nil}, socket}
  end

  def handle_in(unexpected, socket) do
    Logger.error("Unexpected handle_in received by TechChannel: #{inspect(unexpected)}")
    {:noreply, socket}
  end

  def monitor(process_name) do
    spawn(fn ->
      Process.monitor(process_name)

      receive do
        {:DOWN, _ref, :process, {process_name, _}, _reason} ->
          "tc::" <> tech_id = "#{process_name}"
          [client_schema, tech_id] = String.split(tech_id, "-")

          ClientSchema.new(client_schema, tech_id)
          |> Maintenance.log_off()

          {:noreply, nil, nil}
      end
    end)
  end

  defp with_schema(%Maintenance.Tech{__meta__: %{prefix: client_schema}}, data) do
    ClientSchema.new(client_schema, data)
  end
end
