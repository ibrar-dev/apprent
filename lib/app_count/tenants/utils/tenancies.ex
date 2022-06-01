defmodule AppCount.Tenants.Utils.Tenancies do
  alias AppCount.Repo
  alias AppCount.Tenants.Tenancy
  alias AppCount.Leasing.Lease

  import Ecto.Query
  import AppCount.EctoExtensions

  def list_tenancies(_admin, property_id) do
    from(
      tenancy in Tenancy,
      join: unit in assoc(tenancy, :unit),
      join: tenant in assoc(tenancy, :tenant),
      left_join: account in assoc(tenant, :account),
      left_join: autopay in assoc(account, :autopay),
      left_join: bounce in AppCount.Messaging.Bounce,
      on: bounce.target == tenant.email,
      left_join: last_login in subquery(AppCount.Accounts.LoginRepo.last_logins_by_account_id()),
      on: last_login.account_id == account.id,
      where: unit.property_id == ^property_id,
      select: %{
        id: tenancy.id,
        name: fragment("? || ' ' || ?", tenant.first_name, tenant.last_name),
        unit: unit.number,
        account_id: account.id,
        autopay: autopay.active,
        email: tenant.email,
        bounce_id: bounce.id,
        start_date: tenancy.start_date,
        eviction: tenancy.eviction_file_date,
        notice_date: tenancy.notice_date,
        actual_move_out: tenancy.actual_move_out,
        last_login: last_login.inserted_at
      }
    )
    |> Repo.all()
  end

  # called only by  AppCountWeb.API.TenancyController.show()
  def get_tenancy(_admin, id) do
    tenancy_found =
      from(
        tenancy in Tenancy,
        join: tenant in assoc(tenancy, :tenant),
        join: unit in assoc(tenancy, :unit),
        join: property in assoc(unit, :property),
        join: setting in assoc(property, :setting),
        left_join: visit in assoc(tenant, :visits),
        left_join: lease in subquery(lease_with_charges_query()),
        on: lease.customer_ledger_id == tenancy.customer_ledger_id,
        left_join: app in assoc(tenant, :application),
        left_join: memo in assoc(app, :memos),
        left_join: admin in assoc(memo, :admin),
        left_join: other_tenancies in Tenancy,
        on:
          other_tenancies.customer_ledger_id == tenancy.customer_ledger_id and
            other_tenancies.id != tenancy.id,
        left_join: other_tenants in assoc(other_tenancies, :tenant),
        select:
          map(
            tenancy,
            [
              :id,
              :start_date,
              :notice_date,
              :actual_move_in,
              :actual_move_out,
              :expected_move_in,
              :expected_move_out,
              :external_id,
              :eviction_file_date,
              :eviction_notes,
              :eviction_court_date,
              :external_balance,
              :move_out_reason_id,
              :customer_ledger_id
            ]
          ),
        select_merge:
          map(
            tenant,
            [
              :email,
              :first_name,
              :last_name,
              :payment_status,
              :phone,
              :alarm_code,
              :application_id
            ]
          ),
        select_merge: %{
          property: %{
            name: property.name,
            id: property.id,
            notice_period: setting.notice_period
          },
          unit: %{
            id: unit.id,
            number: unit.number,
            property_id: unit.property_id
          },
          application_memos:
            jsonize(memo, [:id, :note, :admin_id, :inserted_at, {:admin_name, admin.name}]),
          leases: jsonize(lease, [:id, :start_date, :end_date, :document_id, :charges]),
          other_tenants:
            jsonize(other_tenants, [
              :id,
              {:tenancy_id, other_tenancies.id},
              :first_name,
              :last_name
            ]),
          tenant_id: tenant.id,
          tenant_external_id: tenant.external_id,
          visits: jsonize(visit, [:id, :description, :admin, :delinquency, :inserted_at]),
          ledger_mode: case_when(setting.sync_ledgers == true, setting.integration, "AppRent")
        },
        where: tenancy.id == ^id,
        group_by: [tenant.id, tenancy.id, unit.id, setting.id, property.id]
      )
      |> Repo.one()

    if tenancy_found do
      tenancy_found
      |> Map.merge(%{
        documents: AppCount.Properties.Utils.Documents.list_documents(tenancy_found.tenant_id),
        emails: AppCount.Messaging.Utils.Emails.list_emails(tenancy_found.tenant_id)
      })
    else
      nil
    end
  end

  def lease_with_charges_query() do
    from(
      lease in Lease,
      left_join: c in assoc(lease, :charges),
      left_join: cc in assoc(c, :charge_code),
      select: map(lease, [:id, :start_date, :end_date, :customer_ledger_id, :document_id]),
      select_merge: %{
        charges:
          jsonize(c, [
            :id,
            :from_date,
            :to_date,
            :amount,
            :charge_code_id,
            {:charge_code, cc.name}
          ])
      },
      group_by: lease.id
    )
  end

  def update_tenancy(id, params) do
    Repo.get(Tenancy, id)
    |> Tenancy.changeset(params)
    |> Repo.update()
  end
end
