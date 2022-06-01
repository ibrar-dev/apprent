defmodule AppCountCom.Showings do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def showing_scheduled(prospect, property, showing) do
    send_email(
      :showing_scheduled,
      prospect.email,
      "[AppRent] Tour Scheduled Confirmation",
      property: property,
      prospect: prospect,
      showing: showing
    )
  end

  def showing_scheduled(admin, prospect, property, showing) do
    address =
      for {k, v} <- property.address, into: %{} do
        {String.to_atom(k), v}
      end

    send_email(
      :admin_showing_scheduled,
      admin.email,
      "[AppRent] #{prospect.name} has scheduled a tour",
      address: address,
      prospect: prospect,
      property: property,
      showing: showing,
      admin: admin
    )
  end

  def showing_reminder_email(s) do
    send_email(
      :showing_reminder,
      s.email,
      "[AppRent] Reminder of tour",
      name: s.name,
      property: s.property,
      date: s.date,
      start_time: s.start_time
    )
  end
end
