defmodule AppCount.Factory do
  use ExMachina.Ecto, repo: AppCount.Repo
  use AppCount.AccountingFactory
  use AppCount.AccountsFactory
  use AppCount.AdminsFactory
  use AppCount.DataFactory
  use AppCount.LeasesFactory
  use AppCount.LedgersFactory
  use AppCount.MaintenanceFactory
  use AppCount.PropertiesFactory
  use AppCount.ProspectsFactory
  use AppCount.RentApplyFactory
  use AppCount.RewardsFactory
  use AppCount.SettingsFactory
  use AppCount.TenantsFactory
  use AppCount.LeasingFactory
  use AppCount.MaterialsFactory
  use AppCount.AppCountAuthFactory
end
