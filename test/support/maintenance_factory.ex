defmodule AppCount.MaintenanceFactory do
  use ExMachina.Ecto, repo: AppCount.Repo
  alias AppCount.Maintenance
  alias AppCount.Materials

  defmacro __using__(_opts) do
    quote do
      def tech_factory do
        %Maintenance.Tech{
          name: "Some Guy",
          email: "tech@yahoo.com",
          phone_number: "1234567890",
          type: "Tech"
        }
      end

      def category_factory do
        %Maintenance.Category{
          name: sequence(:name, &"category-#{&1}")
        }
      end

      def job_factory do
        %Maintenance.Job{
          property: build(:property),
          tech: build(:tech)
        }
      end

      def sub_category_factory do
        %Maintenance.Category{
          name: sequence(:name, &"subcategory-#{&1}"),
          parent: build(:category)
        }
      end

      def order_factory do
        %Maintenance.Order{
          category: build(:sub_category),
          tenant: build(:tenant),
          unit: build(:unit),
          property: build(:property),
          uuid: UUID.uuid4(),
          status: "unassigned"
        }
      end

      def maintenance_note_factory do
        %Maintenance.Note{
          text: "Some Note",
          order: build(:order)
        }
      end

      def assignment_factory do
        %Maintenance.Assignment{
          status: "pending",
          order: build(:order),
          tech: build(:tech),
          tenant_comment: ""
        }
      end

      def stock_factory do
        %Materials.Stock{
          name: sequence(:name, &"Test Stock #{&1}")
        }
      end

      def material_type_factory do
        %Materials.Type{
          name: sequence(:name, &"Test Type #{&1}")
        }
      end

      def material_factory do
        %Materials.Material{
          ref_number: sequence(:ref_number, &"#{&1}"),
          name: sequence(:name, &"material-#{&1}"),
          cost: 2.5,
          inventory: 1,
          desired: 1,
          type: build(:material_type)
        }
      end

      def inventory_factory do
        %Materials.Inventory{
          material: build(:material),
          stock: build(:stock)
        }
      end

      def part_factory do
        %Maintenance.Part{
          order: build(:order),
          name: "Part Name"
        }
      end

      def card_factory do
        today = AppCount.current_date()

        %AppCount.Maintenance.Card{
          deadline: Date.add(today, 5),
          unit: build(:unit),
          completion: %{date: today, name: "Lavana Falls Manager"},
          move_out_date: Date.add(today, 3),
          admin: "Some Admin"
        }
      end

      def card_item_factory do
        today = AppCount.current_date()

        %AppCount.Maintenance.CardItem{
          name: "Inspection",
          completed: today,
          card: build(:card),
          tech: build(:tech),
          completed_by: "Joel Breezy",
          status: "Admin Completed"
        }
      end

      def skill_factory do
        %AppCount.Maintenance.Skill{
          tech: build(:tech),
          category: build(:category)
        }
      end

      def timecard_factory do
        %AppCount.Maintenance.Timecard{
          start_ts: 1_000_000_000,
          tech: build(:tech)
        }
      end
    end
  end
end
