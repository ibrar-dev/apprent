defmodule AppCount.AppCountAuthFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def module_factory do
        %AppCountAuth.Module{
          name: sequence(:module_name, &"Module#{&1}")
        }
      end

      def action_factory do
        %AppCountAuth.Action{
          description: sequence(:module_action_description, &"Action#{&1}"),
          permission_type: "yes-no",
          module: build(:module)
        }
      end
    end
  end
end
