defmodule AppCountWeb.Users.OrderView do
  use AppCountWeb.Users, :view

  @class_dict %{
    "unassigned" => "warning",
    "assigned" => "info",
    "completed" => "primary",
    "cancelled" => "danger"
  }

  @desc_dict %{
    "unassigned" => "Pending Assignment",
    "assigned" => "Work Has Been Assigned",
    "completed" => "Order Completed",
    "cancelled" => "Canceled by Site Staff"
  }

  def status_badge(order) do
    status = order.status
    "<span class='badge badge-pill badge-#{@class_dict[status]}'>#{@desc_dict[status]}</span>"
  end

  def text_note([]) do
    ""
  end

  def text_note(notes) when is_list(notes) do
    last_note = List.last(notes)

    text_note(last_note)
  end

  def text_note(%{"text" => nil}) do
    ""
  end

  def text_note(%{"text" => text}) do
    text
  end

  def image_note_url(nil) do
    "/images/no-image.gif"
  end

  def image_note_url([]) do
    "/images/no-image.gif"
  end

  def image_note_url(notes) when is_list(notes) do
    last_note = List.last(notes)

    image_note_url(last_note)
  end

  # Notes will either have an 'image' string value or a 'text' string
  def image_note_url(%{"id" => _most_recent_id, "image" => nil}) do
    "/images/no-image.gif"
  end

  def image_note_url(%{"id" => most_recent_id, "image" => most_recent_file_name}) do
    env = AppCount.env(:environment)

    "https://s3-us-east-2.amazonaws.com/appcount-maintenance/notes/#{env}/#{most_recent_id}/#{
      most_recent_file_name
    }"
  end

  def has_image(order) do
    Enum.reduce_while(
      order.notes,
      false,
      fn
        %{"image" => nil}, s ->
          {:cont, s}

        %{"image" => _}, _ ->
          {:halt, true}
      end
    )
  end

  def filtered_orders(orders, filters) when is_list(filters) do
    orders
    |> Enum.filter(&Enum.member?(filters, &1.status))
  end

  def filtered_orders(orders, filters) do
    orders
    |> Enum.filter(&(&1.status == filters))
  end
end
