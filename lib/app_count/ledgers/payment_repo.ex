defmodule AppCount.Ledgers.PaymentRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Ledgers.Payment,
    preloads: [
      image_url: [],
      application: [],
      batch: [],
      payment_source: [],
      property: [],
      tenant: [tenancies: [unit: []]],
      customer_ledger: [],
      receipts: [],
      nsf: []
    ]

  def get_payments_by_range(%AppCount.Core.DateTimeRange{} = range, property_ids) do
    payments_in(range, property_ids)
  end

  def show_payment(id) do
    get_aggregate(id)
    |> map_data_for_front_end()
  end

  def formatted_payer_name(%{tenant: nil} = payment) do
    payment.payer_name || ""
  end

  def formatted_payer_name(%{tenant: %{first_name: first, last_name: last}}) do
    "#{first} #{last}"
  end

  def unit(%{tenant: nil}) do
    ""
  end

  def unit(payment) do
    unit_number(payment.tenant.tenancies)
  end

  def tenant_id(%{tenant: nil}) do
    ""
  end

  def tenant_id(payment) do
    tenancy_id(payment.tenant.tenancies)
  end

  defp map_data_for_front_end(payment) do
    %{
      id: payment.id,
      image: image_url(payment.image_url),
      amount: payment.amount,
      tenant_name: formatted_payer_name(payment),
      unit: unit(payment),
      tenant_id: tenant_id(payment),
      property_name: payment.property.name,
      response: payment.response,
      transaction_id: payment.transaction_id,
      source: payment.source,
      description: payment.description,
      admin: payment.admin,
      post_month: payment.post_month,
      status: payment.status,
      edits: payment.edits,
      surcharge: payment.surcharge,
      payer: payment.payer,
      last_4: payment.last_4,
      payer_name: payment.payer_name,
      zip_code_confirmed_at: payment.zip_code_confirmed_at,
      cvv_confirmed_at: payment.cvv_confirmed_at,
      payment_type: payment.payment_type,
      agreement_text: payment.agreement_text,
      agreement_accepted_at: payment.agreement_accepted_at,
      payer_ip_address: payment.payer_ip_address,
      property_id: payment.property_id,
      inserted_at: payment.inserted_at,
      updated_at: payment.updated_at,
      post_error: payment.post_error,
      batch_id: payment.batch_id,
      receipts: payment.receipts,
      rent_application_terms_and_conditions: payment.rent_application_terms_and_conditions
    }
  end

  defp unit_number(nil), do: nil

  defp unit_number([]), do: nil

  defp unit_number([head | _] = _tenancies), do: head.unit.number

  defp tenancy_id(nil), do: nil

  defp tenancy_id([]), do: nil

  defp tenancy_id([head | _] = _tenancies), do: head.id

  defp image_url(nil), do: nil

  defp image_url(image), do: image.url

  # The data is currently diluted bc we were importing a ton of payments from Yardi.
  # We will filter them out here, we stopped importing them 01/2021, so around 06/2021 we can remove the bottom where.
  # We could probably just run a migration function to delete those payments.
  def payments_in(
        %AppCount.Core.DateTimeRange{
          from: from,
          to: to
        },
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids}
      ) do
    from(
      p in Payment,
      where: p.inserted_at >= ^from,
      where: p.inserted_at <= ^to,
      where: p.property_id in ^property_ids,
      where: p.source != "Yardi API",
      order_by: [asc: :inserted_at],
      preload: ^@preloads
    )
    |> Repo.all(prefix: client_schema)
  end

  def check_if_in_task(%AppCount.Core.ClientSchema{name: client_schema, attrs: payment_id}) do
    description = "Export payment #{payment_id}"

    from(
      t in AppCount.Jobs.Task,
      where: t.description == ^description,
      where: t.success,
      select: t.id,
      limit: 1
    )
    |> Repo.one(prefix: client_schema)
    |> case do
      nil -> false
      _ -> true
    end
  end
end
