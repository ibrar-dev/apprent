defmodule AppCount.LeasingFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def leasing_lease_factory() do
        %AppCount.Leasing.Lease{
          start_date:
            AppCount.current_date()
            |> Timex.shift(days: -1),
          end_date:
            AppCount.current_date()
            |> Timex.shift(years: 1),
          date: AppCount.current_date(),
          customer_ledger: build(:customer_ledger),
          unit: build(:unit)
        }
      end

      def leasing_charge_factory() do
        %AppCount.Leasing.Charge{
          lease: build(:leasing_lease),
          amount: 500,
          charge_code: build(:charge_code)
        }
      end

      def bluemoon_external_lease_factory() do
        params = %{
          rent: 1500,
          start_date: AppCount.current_date(),
          lease_date: AppCount.current_date(),
          end_date: Timex.shift(AppCount.current_date(), years: 1),
          unit: "1123A",
          residents: [%{name: "Simon Resident", email: "email"}]
        }

        %AppCount.Leasing.ExternalLease{
          unit: build(:unit),
          provider: "BlueMoon",
          external_id: "123456",
          signature_id: "123456",
          admin: build(:admin),
          parameters: AppCount.Leasing.BlueMoon.Parameters.raw_parameters(params)
        }
      end
    end
  end
end
