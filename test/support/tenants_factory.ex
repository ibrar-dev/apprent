defmodule AppCount.TenantsFactory do
  use ExMachina.Ecto, repo: AppCount.Repo
  alias AppCount.Tenants

  defmacro __using__(_opts) do
    quote do
      def tenant_factory do
        %Tenants.Tenant{
          first_name: sequence(:first_name, &"Larry-#{&1}"),
          last_name: "Smith",
          email: sequence(:email, &"someguy#{&1}@yahoo.com"),
          uuid: UUID.uuid4()
        }
      end

      def tenancy_factory do
        %Tenants.Tenancy{
          tenant: build(:tenant),
          unit: build(:unit),
          customer_ledger: build(:customer_ledger),
          start_date: AppCount.current_date()
        }
      end
    end
  end
end
