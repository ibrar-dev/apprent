defmodule AppCount.Leases.Utils.Screenings do
  alias AppCount.Admins
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Properties
  alias AppCount.Tenants.Utils.CreateTenant
  alias AppCount.Leases.Screening
  alias AppCount.Properties.Processor
  alias AppCount.Leases.Lease
  alias AppCount.Leases.Utils.ParseScreening
  import Ecto.Query
  import AppCount.EctoExtensions
  import AppCount.Utils, only: [indifferent: 2, matched_put: 3]
  alias AppCount.Core.ClientSchema

  def create_screening(params, instant_screen \\ false, schema) do
    %Screening{}
    |> Screening.changeset(fill_in_lease_info(params))
    |> Repo.insert(prefix: schema)
    |> do_screening(instant_screen, schema)
  end

  def update_screening(id, params) do
    Repo.get(Screening, id)
    |> Screening.changeset(params)
    |> Repo.update()
  end

  def delete_screening(id) do
    Repo.get(Screening, id)
    |> Repo.delete()
  end

  def do_screening({:error, _} = e, _instant_screen, _), do: e

  # UNTESTED
  # Log says: ** (Ecto.StaleEntryError) attempted to delete a stale struct:
  def do_screening({:ok, screening}, instant_screen, schema) do
    applicant_keys =
      %TenantSafe.Applicant{}
      |> Map.from_struct()
      |> Map.keys()

    %TenantSafe.Applicant{}
    |> Map.merge(Map.take(screening, applicant_keys))
    |> Map.merge(%{
      dob: "#{screening.dob}",
      ref: "#{screening.id}",
      ssn: AppCount.Crypto.LocalCryptoServer.decrypt!(screening.ssn)
    })
    |> TenantSafe.SubmitOrder.submit(tenant_safe_credentials_for(screening.property_id))
    |> case do
      %{order_id: ""} ->
        Repo.delete(screening)
        {:error, "Request Failed"}

      %{order_id: order_id} ->
        result = update_screening(screening.id, %{order_id: order_id})
        property = Properties.get_property(ClientSchema.new(schema, screening.property_id))

        managers = Admins.admins_for(ClientSchema.new(schema, screening.property_id), ["Admin"])

        tenant_safe_url = Repo.get(Screening, screening.id, prefix: schema).url

        AppCount.Core.Tasker.start(fn ->
          notify_all_managers(managers, tenant_safe_url, property, instant_screen, screening)
        end)

        result

      _ ->
        Repo.delete(screening, prefix: schema)
        {:error, "Request Failed"}
    end
  end

  # UNTESTED
  def notify_all_managers(managers, tenant_safe_url, property, instant_screen, screening) do
    managers
    |> Enum.each(fn manager ->
      if instant_screen do
        AppCountCom.NotifyManagersScreening.notify_managers_instant_screening(
          screening,
          tenant_safe_url,
          property,
          manager
        )
      else
        AppCountCom.NotifyManagersScreening.notify_managers_screening(
          screening,
          tenant_safe_url,
          property,
          manager
        )
      end
    end)
  end

  def tenant_safe_credentials_for(property_id) do
    [user_id, password, product_type] =
      from(
        p in Processor,
        where: p.property_id == ^property_id and p.type == ^"screening",
        select: p.keys
      )
      |> Repo.one()

    %TenantSafe.Credentials{user_id: user_id, password: password, product_type: product_type}
  end

  def handle_postback(params) do
    params = convert_params(params)
    screening = Repo.get(Screening, params.ref)

    new_data =
      [Map.get(params, :gateway_xml)]
      |> Enum.filter(& &1)

    screening
    |> Screening.changeset(Map.put(params, :xml_data, screening.xml_data ++ new_data))
    |> Repo.update()
  end

  def get_screening_status(id) do
    screening = Repo.get(Screening, id)

    case TenantSafe.GetOrderStatus.submit(
           screening.order_id,
           tenant_safe_credentials_for(screening.property_id)
         ) do
      %{status: _} = params ->
        screening
        |> Screening.changeset(convert_params(params))
        |> Repo.update!()

      _ ->
        screening
    end
  end

  def approve_screening(id) do
    params =
      from(
        s in Screening,
        where: s.id == ^id,
        where: not is_nil(s.lease_id),
        select: map(s, [:first_name, :last_name, :email, :phone, :lease_id])
      )
      |> Repo.one()

    case CreateTenant.create_tenant(params, lease_id: params.lease_id) do
      {:error, _, _} = e ->
        e

      {:ok, %{tenant: tenant}} = e ->
        update_screening(id, %{tenant_id: tenant.id})
        e
    end
  end

  def adverse_action_params(screening_id) do
    p =
      from(
        s in Screening,
        join: p in assoc(s, :property),
        where: s.id == ^screening_id,
        select: %{
          property: p,
          data: s.xml_data,
          name: fragment("? || ' ' || ?", s.first_name, s.last_name)
        },
        select_merge: map(s, [:city, :street, :state, :zip])
      )
      |> Repo.one()

    Map.put(p, :data, ParseScreening.parse_gateway_xml(p.data))
  end

  defp convert_params(%{decision: ""} = params) do
    convert_params(Map.delete(params, :decision))
  end

  defp convert_params(%{status: "x:" <> status} = params) do
    convert_params(Map.put(params, :status, status))
  end

  defp convert_params(params), do: params

  defp fill_in_lease_info(params) do
    if indifferent(params, :property_id) do
      params
    else
      lease_id = params["lease_id"] || params[:lease_id]

      {property_id, rent, orders} =
        from(
          l in Lease,
          join: t in assoc(l, :tenants),
          left_join: s in assoc(t, :screening),
          join: u in assoc(l, :unit),
          join: c in assoc(l, :charges),
          where: l.id == ^lease_id,
          where: c.charge_code_id == ^Accounting.SpecialAccounts.get_charge_code(:rent).id,
          select: {u.property_id, c.amount, array(s.order_id)},
          group_by: [c.id, u.id]
        )
        |> Repo.one()

      params
      |> matched_put(:property_id, property_id)
      |> matched_put(:rent, rent)
      |> matched_put(:linked_orders, orders)
    end
  end
end
