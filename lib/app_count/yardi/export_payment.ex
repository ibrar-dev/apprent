defmodule AppCount.Yardi.ExportPayment do
  import Ecto.Query
  alias AppCount.Properties.Processors
  alias AppCount.Tasks.Enqueue
  alias AppCount.Core.ClientSchema

  def perform(payment_id, schema, gateway \\ Yardi.Gateway) do
    from(
      payment in AppCount.Ledgers.Payment,
      join: property in assoc(payment, :property),
      left_join: tenant in assoc(payment, :tenant),
      where: payment.id == ^payment_id,
      select: %{
        property_id: property.external_id,
        p_id: property.id,
        payment_id: payment.id,
        property_name: property.name,
        time_zone: property.time_zone,
        payment_inserted_at: payment.inserted_at,
        tenant_id: tenant.id,
        transaction_id: payment.transaction_id,
        source: payment.source,
        amount: type(payment.amount, :float)
      }
    )
    |> AppCount.Repo.one(prefix: schema)
    |> put_payment_date()
    |> put_t_code(schema)
    |> perform_import(ClientSchema.new(schema, gateway))
  end

  def put_t_code(%{payment_date: date, tenant_id: tenant_id} = params, schema)
      when not is_nil(tenant_id) do
    # TODO currently payments are associated with a tenant,
    # we will need to change it to explicitly associate them with a tenancy.
    # For now just guess that the payment is for the first current tenancy
    date =
      date
      |> Timex.shift(days: 30)

    tenancy =
      AppCount.Tenants.TenancyRepo.current_tenancies_for_tenant(tenant_id, date, schema)
      |> List.first()

    Map.put(params, :customer_id, Map.get(tenancy, :external_id))
  end

  def put_t_code(params, _schema), do: params

  # Get the payment date by converting the payment's `inserted_at` field (UTC
  # datetime) into property local time
  def put_payment_date(nil) do
    nil
  end

  def put_payment_date(params) do
    inserted_at = params.payment_inserted_at
    time_zone = params.time_zone

    post_date =
      AppCount.Core.Clock.to_zone(inserted_at, time_zone)
      |> DateTime.to_date()

    params
    |> Map.put(:payment_date, post_date)
    |> Map.drop([:payment_inserted_at, :time_zone])
  end

  def perform_import(nil, _), do: raise("Payment Not found")

  def perform_import(%{tenant_id: nil}, _), do: raise("Payment does not come from a tenant")

  def perform_import(%{property_id: nil, property_name: name}, _),
    do: raise("No external ID found for property #{name}")

  def perform_import(%{customer_id: nil}, _), do: raise("No external ID found for tenant")

  def perform_import(params, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: gateway
      }) do
    credentials =
      Processors.processor_credentials(ClientSchema.new(client_schema, params.p_id), "management")

    params
    |> Map.put(:credentials, credentials)
    |> Map.to_list()
    |> gateway.export_payment()
    |> handle_response(ClientSchema.new(client_schema, params.payment_id))
  end

  defp handle_response({:error, err}, %AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: payment_id
       }) do
    AppCount.Ledgers.Utils.Payments.handle_post_error(
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: payment_id
      },
      err
    )

    AppCount.Tasks.Task.log("ERROR: #{err}")
  end

  defp handle_response({:ok, msg}, _), do: AppCount.Tasks.Task.log(msg)

  def export_payment(payment_id, client_schema \\ "dasmen") do
    desc = "Export payment #{payment_id}"
    Enqueue.enqueue(desc, &perform/2, [payment_id, client_schema], client_schema)
  end
end
