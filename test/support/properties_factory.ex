defmodule AppCount.PropertiesFactory do
  use ExMachina.Ecto, repo: AppCount.Repo
  alias AppCount.Properties

  defmacro __using__(_opts) do
    quote do
      def property_factory do
        %Properties.Property{
          name: "Test Property",
          code: sequence(:code, &"test-#{&1}"),
          address: %{
            zip: "28205",
            street: "3317 Magnolia Hill Dr",
            state: "NC",
            city: "Charlotte"
          },
          terms: "These are my terms, take 'em or leave 'em",
          setting: build(:setting),
          social: %{}
        }
      end

      def mailer_property_factory do
        Map.merge(build(:property), %{icon: "https://something", logo: "https://something"})
      end

      def phone_line_factory do
        %Properties.PhoneLine{
          number: "(123) 456-7890",
          property: build(:property)
        }
      end

      def package_factory do
        %Properties.Package{
          name: "Test Package",
          condition: "Good",
          status: "Delivered",
          carrier: "USPS",
          notes: "test test",
          admin: "Tester",
          reason: "Show ID",
          unit: build(:unit),
          tenant: build(:tenant)
        }
      end

      def setting_factory do
        %Properties.Setting{
          default_bank_account: build(:bank_account)
        }
      end

      def property_person_factory do
        %Properties.Occupant{
          first_name: "Billy",
          last_name: "Bob",
          lease: build(:lease)
        }
      end

      def unit_factory do
        property = build(:property)

        %Properties.Unit{
          number: sequence(:number, &"#{&1}"),
          property: property,
          features: [feature_factory()],
          uuid: UUID.uuid4()
        }
      end

      def feature_factory do
        %Properties.Feature{
          name: sequence(:name, &"#{&1} Bedrooms"),
          price: 250,
          start_date: AppCount.current_date(),
          property: build(:property)
        }
      end

      def floor_plan_factory do
        %AppCount.Properties.FloorPlan{
          name: "Standard",
          property: build(:property)
        }
      end

      def floor_plan_feature_factory do
        %AppCount.Properties.FloorPlanFeature{
          feature: build(:feature),
          floor_plan: build(:floor_plan)
        }
      end

      def processor_factory do
        %Properties.Processor{
          property: build(:property),
          name: "TenantSafe",
          type: "screening",
          keys: ["welcome", "welcome", "Employment Search"]
        }
      end

      def charge_factory do
        %Properties.Charge{
          amount: 100,
          lease: build(:lease),
          charge_code: build(:charge_code),
          next_bill_date: AppCount.current_date()
        }
      end

      def resident_event_factory do
        %Properties.ResidentEvent{
          property: build(:property),
          name: "Some Event",
          date: AppCount.current_date(),
          start_time: 600,
          end_time: 900,
          admin: "Mr. Admin"
        }
      end

      def visit_factory do
        %Properties.Visit{
          property: build(:property),
          tenant: build(:tenant),
          description: "Something happened",
          admin: "Some Guy"
        }
      end

      def occupant_factory do
        %Properties.Occupant{
          lease: build(:lease),
          first_name: "Occupant",
          last_name: "Occupying",
          email: "someguy@somewhere.com"
        }
      end

      def eviction_factory do
        %AppCount.Properties.Eviction{
          file_date:
            AppCount.current_date()
            |> Timex.shift(years: 1),
          court_date:
            AppCount.current_date()
            |> Timex.shift(years: 1),
          lease: build(:lease)
        }
      end

      def tenant_document_factory do
        %AppCount.Properties.Document{
          name: "Some Doc Name",
          type: "Some Doc Type",
          visible: false,
          tenant: build(:tenant),
          document: build(:upload)
        }
      end

      def default_lease_charge_factory do
        %AppCount.Units.DefaultLeaseCharge{
          price: 80,
          floor_plan: build(:floor_plan),
          default_charge: true,
          charge_code: build(:charge_code)
        }
      end

      def letter_template_factory do
        %AppCount.Properties.LetterTemplate{
          name: "Test Template",
          body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
          property: build(:property)
        }
      end

      def recurring_letter_factory do
        %AppCount.Properties.RecurringLetter{
          letter_template: build(:letter_template),
          admin: build(:admin),
          notify: true,
          visible: true,
          name: "Recurring Letter"
        }
      end

      def resident_event_attendance_factory do
        %AppCount.Properties.ResidentEventAttendance{
          tenant: build(:tenant),
          resident_event: build(:resident_event)
        }
      end
    end
  end
end
