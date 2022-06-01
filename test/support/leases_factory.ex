defmodule AppCount.LeasesFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def renewal_period_factory do
        today = AppCount.current_date()

        %AppCount.Leasing.RenewalPeriod{
          creator: "Auto",
          approval_date: today,
          approval_admin: "SomeAdmin",
          start_date: Timex.beginning_of_month(today),
          end_date: Timex.end_of_month(today),
          property: build(:property)
        }
      end

      def renewal_package_factory() do
        %AppCount.Leasing.RenewalPackage{
          renewal_period: build(:renewal_period),
          min: 10,
          max: 14,
          base: "Market Rent",
          dollar: false,
          amount: 10
        }
      end

      def custom_package_factory() do
        %AppCount.Leasing.CustomPackage{
          renewal_package: build(:renewal_package),
          lease: build(:lease),
          amount: 800
        }
      end

      def lease_factory do
        %AppCount.Leases.Lease{
          start_date:
            AppCount.current_date()
            |> Timex.shift(days: -1),
          end_date:
            AppCount.current_date()
            |> Timex.shift(years: 1),
          tenants: [build(:tenant)],
          unit: build(:unit)
        }
      end

      def lease_form_factory do
        %AppCount.Leases.Form{
          lease: build(:lease)
        }
      end

      def screening_factory do
        %AppCount.Leases.Screening{
          property: build(:property),
          person: build(:rent_apply_person),
          first_name: "Joe",
          last_name: "Clean",
          phone: "1234567890",
          email: "joeclean@gmail.com",
          street: "123 Sesame St.",
          city: "Chicago",
          state: "IL",
          zip: "53210",
          income: 1500,
          rent: 1000,
          linked_orders: [],
          dob: Timex.shift(AppCount.current_date(), years: -30),
          ssn: "111-22-3333",
          decision: "Dunno",
          status: "pending",
          order_id: "86018",
          url: "http://idontknowanymore.com"
        }
      end
    end
  end
end
