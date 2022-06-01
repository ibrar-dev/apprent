defmodule AppCountCom.Parts do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def part_updated(%{status: "pending"} = part, email, name, ticket, property) do
    send_email(
      :maintenance_part_pending,
      email,
      "[AppWork] An update has been posted for your work order #{ticket}.",
      name: name,
      ticket: ticket,
      part: part,
      property: property
    )
  end

  def part_updated(%{status: "ordered"} = part, email, name, ticket, property) do
    send_email(
      :maintenance_part_ordered,
      email,
      "[AppWork] An update has been posted for your work order #{ticket}.",
      name: name,
      ticket: ticket,
      part: part,
      property: property
    )
  end

  def part_updated(%{status: "delivered"} = part, email, name, ticket, property) do
    subject = "[AppWork] An update has been posted for your work order #{ticket}."

    send_email(
      :maintenance_part_delivered,
      email,
      subject,
      name: name,
      ticket: ticket,
      part: part,
      property: property
    )
  end

  def part_updated(%{status: "canceled"} = part, email, name, ticket, property) do
    subject = "[AppWork] An update has been posted for your work order #{ticket}."

    send_email(
      :maintenance_part_canceled,
      email,
      subject,
      name: name,
      ticket: ticket,
      part: part,
      property: property
    )
  end
end
