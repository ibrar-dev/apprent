defmodule AppCount.MaterialsFactory do
  use ExMachina.Ecto, repo: AppCount.Repo
  alias AppCount.Materials

  defmacro __using__(_opts) do
    quote do
      def toolbox_item_factory do
        %Materials.ToolboxItem{
          admin: "Some one",
          stock: build(:stock),
          material: build(:material),
          tech: build(:tech)
        }
      end
    end
  end
end
