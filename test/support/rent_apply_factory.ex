defmodule AppCount.RentApplyFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def rent_application_factory do
        %AppCount.RentApply.RentApplication{
          property: build(:property)
        }
      end

      def full_rent_application_factory do
        %AppCount.RentApply.RentApplication{
          property: build(:property),
          persons: [build(:rent_apply_person, application: nil)],
          payments: [build(:payment)]
        }
      end

      def rent_apply_person_factory do
        %AppCount.RentApply.Person{
          application: build(:rent_application),
          full_name: "Dave Smith",
          ssn: "123-45-6789",
          email: "someemail@thisis.com",
          dob: AppCount.current_date(),
          home_phone: "(123) 456-7890",
          dl_number: "1231242",
          dl_state: "PA",
          status: "Lease Holder"
        }
      end

      def history_factory do
        %AppCount.RentApply.History{
          application: build(:rent_application),
          address: "34 Jefferson Ave 5L Brooklyn NY",
          residency_length: "2 years",
          current: true,
          street: "123 Main St",
          city: "Brooklyn",
          state: "NY",
          zip: "43123"
        }
      end
    end
  end
end
