defmodule AppCountCom.WorkOrders do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def order_assigned(tech, tech_image, ticket, property, email, first_name, last_name) do
    send_email(
      :order_assigned,
      email,
      "[AppRent] Your service request, #{ticket} has been assigned",
      property: property,
      name: "#{first_name} #{last_name}",
      tech: tech,
      ticket: ticket,
      tech_image: tech_image
    )
  end

  def tech_arrival(time, tech, ticket, property, email) do
    send_email(
      :tech_arrival,
      email,
      "[AppRent] Your tech for #{ticket} is on their way",
      time: time,
      property: property,
      tech: tech
    )
  end

  def order_cancelled(email, name, ticket, %{"reason" => reason}, property) do
    subject = "[AppRent] Your service request has been cancelled"

    send_email(
      :order_cancelled,
      email,
      subject,
      name: name,
      ticket: ticket,
      reason: reason,
      property: property
    )
  end

  def new_note_on_work_order(
        email,
        recipient_name,
        work_order_id,
        work_order_description,
        note,
        author_name,
        property,
        link \\ ""
      ) do
    send_email(
      :new_note_on_work_order,
      email,
      "[AppRent] New Note on Work Order #{work_order_id}",
      work_order_id: work_order_id,
      work_order_description: work_order_description,
      note: note,
      author_name: author_name,
      link: link,
      property: property,
      recipient_name: recipient_name
    )
  end

  def email_resident(order, email, name, admin, note, property) do
    send_email(
      :email_to_resident,
      email,
      "[AppWork] A note has been added to your request",
      order: order,
      name: name,
      admin: admin,
      note: note,
      property: property
    )
  end

  def order_prioritized(email, order, tech, property) do
    send_email(
      :order_prioritized,
      email,
      "[AppWork] A work order has been marked as priority",
      order: order,
      category: order.category.name,
      name: tech.name,
      unit: order.unit.number,
      propName: property.name,
      property: property
    )
  end

  def power_out(unit, email, tech, property) do
    send_email(
      :power_out,
      email,
      "[AppWork] Unit without power",
      name: tech.name,
      unit: unit,
      property: property
    )
  end

  def order_completed(email, ticket, tenant_notes, token, property) do
    sub = "[AppRent] Your order #{ticket} is complete"

    rate_url = "#{AppCount.namespaced_url('maintenance')}/orders/rate?token=#{token}"

    send_email(
      :order_completed,
      email,
      sub,
      ticket: ticket,
      notes: tenant_notes,
      rate_url: rate_url,
      property: property
    )
  end

  def daily_snapshot(admin, date, properties) do
    args = [properties: properties, date: date, layout: :admin]
    send_email(:daily_snapshot, admin.email, "[AppWork] Daily Snapshot", args)
  end

  def callback_email(techs, params, admin, property) do
    previous_name =
      case params["completed_by"] do
        nil -> "Unknown"
        _ -> params["completed_by"]
      end

    send_email(
      :card_item_callback,
      techs.email,
      "[AppRent] Make Ready Callback",
      name: techs.name,
      previous_admin: previous_name,
      date: params["completed"],
      name: params["name"],
      current_admin: admin,
      unit: property.unit.number,
      property_name: property.property.name,
      property: property.property
    )
  end

  def unit_ready(unit, property, admin) do
    send_email(
      :unit_ready,
      admin.email,
      "[AppWork] A unit is now ready",
      unit: unit,
      property: property
    )
  end

  def ms_daily_report(info, admin) do
    techs =
      info.techs
      |> length

    args = [
      open: info.open,
      created: info.created,
      completed: info.completed,
      notes: "",
      make_readies_completed: info.make_readies_completed,
      not_ready_units: info.not_ready_units,
      techs: techs,
      admin: admin,
      layout: :admin
    ]

    send_email(
      :ms_daily_report,
      admin.email,
      "[AppRent Maintenance] Automated Daily Maintenance Report",
      args
    )
  end

  def ms_daily_report(admin, notes, info, sender) do
    techs =
      info.techs
      |> length

    args = [
      open: info.open,
      created: info.created,
      completed: info.completed,
      notes: notes,
      make_readies_completed: info.make_readies_completed,
      not_ready_units: info.not_ready_units,
      techs: techs,
      sender: sender,
      admin: admin,
      layout: :admin
    ]

    send_email(
      :ms_daily_report,
      admin.email,
      "[AppWork] #{sender.name} has sent you a daily report",
      args
    )
  end

  def duplicate_assignments(assignments) do
    args = [
      assignments: assignments,
      layout: :admin
    ]

    send_email(
      :duplicate_assignments,
      "dastor@dasmenresidential.com",
      "[AppWork] Duplicate Assignments",
      args
    )
  end

  def assignment_withdrawal(property, tech, ticket, assignment, admin) do
    send_email(
      :assignment_withdrawal,
      admin.email,
      "[AppWork] A Tech has withdrawn from an assignment",
      tech: tech,
      ticket: ticket,
      assignment: assignment,
      property: property
    )
  end

  def reminder_to_rate_order({tenant, ticket, email, property, id}) do
    send_email(
      :reminder_to_rate_order,
      email,
      "[AppRent] Reminder to rate your recent order",
      tenant: tenant,
      ticket: ticket,
      id: id,
      property: property
    )
  end

  def order_outsourced(category, unit, vendor, tech, property) do
    send_email(
      :order_outsourced,
      tech.email,
      "[AppWork] Order has been outsourced",
      name: tech.name,
      vendor: vendor.name,
      unit: unit,
      order: category,
      property: property
    )
  end

  def order_date_updated(category, unit, tenant, property, vendor, old_date, new_date) do
    send_email(
      :order_outsource_date_change,
      tenant.email,
      "[AppWork] Order date has been updated",
      vendor: vendor.name,
      name: "#{tenant.first_name} #{tenant.last_name}",
      unit: unit.number,
      order: category.name,
      old_date: old_date,
      new_date: new_date,
      property: property
    )
  end

  def tenant_outsource(property, tenant, ticket, vendor, category) do
    send_email(
      :tenant_outsource,
      tenant.email,
      "[AppWork] Service Request Update",
      name: "#{tenant.first_name} #{tenant.last_name}",
      vendor: vendor.name,
      category: category,
      ticket: ticket,
      property: property
    )
  end

  def tenant_outsource_completed(property, tenant, vendor, category, _ticket) do
    send_email(
      :tenant_outsource,
      tenant.email,
      "[AppWork] Order request update",
      name: "#{tenant.first_name} #{tenant.last_name}",
      vendor: vendor.name,
      order: category.name,
      property: property
    )
  end
end
