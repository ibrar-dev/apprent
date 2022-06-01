defmodule AppCount.Leasing.Utils.RenewalRent do
  alias AppCount.Leasing.Lease
  alias AppCount.Core.ClientSchema

  def rent_for(
        %ClientSchema{name: client_schema, attrs: %Lease{} = lease},
        %Date{} = start_date,
        %Date{} = end_date
      ) do
    term =
      end_date
      |> Timex.shift(days: 1)
      |> Timex.diff(start_date, :months)

    AppCount.Leasing.Utils.RenewalPackages.package_price(
      %ClientSchema{name: client_schema, attrs: lease},
      term,
      start_date
    )
  end

  def rent_for(%ClientSchema{name: client_schema, attrs: %Lease{} = lease}, start_date, end_date) do
    rent_for(
      %ClientSchema{name: client_schema, attrs: lease},
      Date.from_iso8601!(start_date),
      Date.from_iso8601!(end_date)
    )
  end
end
