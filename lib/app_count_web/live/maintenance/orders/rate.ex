defmodule AppCountWeb.Live.Maintenance.OrdersLive.Rate do
  use AppCountWeb, :live_view
  alias AppCount.Maintenance
  alias AppCountWeb.Endpoint

  def mount(%{"token" => token}, _session, socket) do
    case get_decryption(token) do
      {:ok, %{uuid: uuid}} ->
        order = Maintenance.get_order_public(uuid, :rate)

        assignment = Enum.find(order.assignments, &(&1.status == "completed"))

        socket =
          assign(
            socket,
            page_title: "Rate Maintenance Request",
            order: order,
            assignment: %{
              rating: assignment.rating,
              resident_comment: assignment.resident_comment
            }
          )

        {
          :ok,
          socket
        }

      _ ->
        {
          :ok,
          redirect(
            socket,
            external:
              AppCountWeb.Router.Helpers.user_session_url(
                Endpoint,
                :index
              )
          )
        }
    end
  end

  def render(assigns) do
    ~L"""
      <div class="container pt-3">
        <div class="row d-flex justify-content-center">
          <div class="col d-flex justify-content-start">
            <div class="card d-flex flex-fill">
              <div class="card-header d-flex justify-content-between">
                <span>Rate Order #<%= @order.ticket %></span>
                <span><%= category_display(@order.category) %></span>
              </div>
              <div class="card-body">
                <form phx-change="updateState">
                  <div class="d-flex flex-column">
                    <div class="input-group mb-3">
                      <input type="text"
                             value="<%= @assignment.resident_comment %>"
                             class="form-control"
                             name="resident_comment"
                             placeholder="Leave a comment"
                             aria-label="Leave a comment" />
                    </div>
                    <div class="d-flex flex-row">
                      <span class="<%= solid_star(@assignment.rating, 1) %> live-star fa-star fa-2x cursor-pointer"
                            phx-click="rating" phx-value-rating="1"></span>
                      <span class="<%= solid_star(@assignment.rating, 2) %> live-star fa-star fa-2x cursor-pointer"
                            phx-click="rating" phx-value-rating="2"></span>
                      <span class="<%= solid_star(@assignment.rating, 3) %> live-star fa-star fa-2x cursor-pointer"
                            phx-click="rating" phx-value-rating="3"></span>
                      <span class="<%= solid_star(@assignment.rating, 4) %> live-star fa-star fa-2x cursor-pointer"
                            phx-click="rating" phx-value-rating="4"></span>
                      <span class="<%= solid_star(@assignment.rating, 5) %> live-star fa-star fa-2x cursor-pointer"
                            phx-click="rating" phx-value-rating="5"></span>
                    </div>
                    <div class="d-flex justify-content-end mt-3">
                      <button phx-click="submitRating" type="button" class="btn btn-success">Submit</button>
                    </div>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    """
  end

  def handle_event("submitRating", _, socket) do
    %{order: order, assignment: assignment} = socket.assigns

    original_assignment = Enum.find(order.assignments, &(&1.status == "completed"))

    socket =
      case can_submit(assignment) do
        {:error, message} ->
          put_flash(socket, :error, message)

        _ ->
          AppCount.Maintenance.Utils.Public.Orders.update_assignment(
            %AppCount.Core.ClientSchema{
              name: order.__meta__prefix,
              attrs: original_assignment.id
            },
            assignment
          )
          |> case do
            {:ok, _} -> put_flash(socket, :success, "Thank you for your feedback")
            _ -> put_flash(socket, :error, "Something went wrong.")
          end
      end

    {:noreply, socket}
  end

  def handle_event("updateState", %{"resident_comment" => resident_comment}, socket) do
    %{assignment: assignment} = socket.assigns

    assigment = Map.put(assignment, :resident_comment, resident_comment)

    {:noreply, assign(socket, assignment: assigment)}
  end

  def handle_event("rating", %{"rating" => string}, socket) do
    {rating, _} = Integer.parse(string)

    assigment = Map.put(socket.assigns.assignment, :rating, rating)

    {:noreply, assign(socket, assignment: assigment)}
  end

  def can_submit(assignment) do
    cond do
      is_nil(assignment.rating) and is_nil(assignment.resident_comment) ->
        {:error, "All fields are required"}

      is_nil(assignment.rating) ->
        {:error, "Rating is required"}

      is_nil(assignment.resident_comment) ->
        {:error, "A comment is required"}

      true ->
        true
    end
  end

  def solid_star(rating, _) when is_nil(rating), do: "far"
  def solid_star(rating, number) when number <= rating, do: "fas"
  def solid_star(_rating, _number), do: "far"

  def category_display(category) do
    "#{category.parent.name} - #{category.name}"
  end

  def get_decryption(token) do
    AppCountWeb.Token.verify(token)
  end
end
