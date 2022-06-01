defmodule AppCount.RewardsFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def accomplishment_factory do
        %AppCount.Rewards.Accomplishment{
          amount: 50,
          reason: "dunno",
          tenant: build(:tenant),
          type: build(:reward_type)
        }
      end

      def reward_factory do
        %AppCount.Rewards.Reward{
          name: "Some Name",
          points: 1000,
          promote: true,
          url: "https://www.google.com"
        }
      end

      def reward_type_factory do
        %AppCount.Rewards.Type{
          name: sequence(:name, &"Reward Type ##{&1}"),
          points: 100
        }
      end
    end
  end
end
