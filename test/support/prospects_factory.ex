defmodule AppCount.ProspectsFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def prospect_factory do
        %AppCount.Prospects.Prospect{
          name: "Test",
          contact_date:
            AppCount.current_date()
            |> Timex.shift(years: 1),
          contact_type: "Test",
          property: build(:property),
          email: "test@test.com"
        }
      end

      def showing_factory do
        %AppCount.Prospects.Showing{
          date:
            AppCount.current_date()
            |> Timex.shift(years: 1),
          prospect: build(:prospect),
          property: build(:property),
          start_time: 540,
          end_time: 630
        }
      end

      def closure_factory do
        %AppCount.Prospects.Closure{
          property: build(:property),
          date:
            AppCount.current_date()
            |> Timex.shift(days: 1),
          start_time: 780,
          end_time: 900,
          reason: "Lunch Retreat",
          admin: "User 1"
        }
      end
    end
  end
end
