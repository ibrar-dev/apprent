defmodule AppCount.Yardi.Fixtures do
  alias Yardi.Response.GetResidents.Tenant

  def valid_tenant(params \\ %{}) do
    today = AppCount.current_date()

    %Tenant{
      current_rent: "1000.00",
      email: "some_email@example.com",
      error: nil,
      external_id: "t0038684",
      first_name: "John",
      last_name: "Doe",
      lease_end: "#{Timex.shift(today, months: 11)}",
      lease_start: "#{Timex.shift(today, months: -1, days: -1)}",
      phone: "1256794859",
      property_id: "3030",
      status: "future",
      unit_id: "1212",
      expected_move_in_date: "#{Timex.shift(today, months: -1)}",
      actual_move_in_date: "#{Timex.shift(today, months: -1)}",
      expected_move_out_date: nil,
      actual_move_out_date: nil
    }
    |> Map.merge(params)
  end

  def invalid_tenant(params \\ %{}) do
    %Tenant{
      current_rent: "1000.00",
      email: "some_other_email@example.com",
      error: nil,
      external_id: "t0038692",
      first_name: "Jane",
      last_name: "Doe",
      lease_end: nil,
      lease_start: nil,
      phone: "1256794859",
      property_id: "3030",
      status: "future",
      unit_id: "1213",
      expected_move_in_date: nil,
      actual_move_in_date: nil,
      expected_move_out_date: nil,
      actual_move_out_date: nil
    }
    |> Map.merge(params)
  end
end
