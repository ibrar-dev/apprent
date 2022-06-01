defmodule AppCount.RentApply do
  alias AppCount.Repo
  alias AppCount.RentApply.Person
  alias AppCount.RentApply.Document
  alias AppCount.RentApply.Utils.RentApplications
  alias AppCount.RentApply.Utils.BlueMoon
  alias AppCount.RentApply.Utils.Screening
  alias AppCount.RentApply.Utils.Processing
  alias AppCount.RentApply.Utils.Ledgers
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def list_applications(admin, property_id, start_date, end_date),
    do: RentApplications.list_applications(admin, property_id, start_date, end_date)

  def list_applications(admin, options), do: RentApplications.list_applications(admin, options)

  def list_saved_forms(admin, options),
    do: RentApplications.list_saved_forms(admin, options)

  def get_applications_for_property(property_code),
    do: RentApplications.get_applications_for_property(property_code)

  def get_property_applications(property_id),
    do: RentApplications.get_property_applications(property_id)

  def get_applicants_for_payments(property_id),
    do: RentApplications.get_applicants_for_payments(property_id)

  def get_application(id), do: RentApplications.get_application(id)
  def get_application_data(id), do: RentApplications.get_application_data(id)

  def get_application(id, property_code, _admin),
    do: RentApplications.get_application(id, property_code, nil)

  def update_application(id, params), do: RentApplications.update_application(id, params)

  def full_update_application(id, params),
    do: RentApplications.full_update_application(id, params)

  def process_application(property_id, params),
    do: RentApplications.process_application(property_id, params)

  def create_document(params), do: RentApplications.create_document(params)
  def create_memo(params, admin), do: RentApplications.create_memo(params, admin)

  def preapprove(app, params), do: Processing.preapprove(app, params)
  def approve(app), do: Processing.approve(app)
  def bypass_approve(id, bluemoon_info), do: Processing.bypass_approve(id, bluemoon_info)
  def decline(app), do: Processing.decline(app)
  def application_signed(app_id), do: Processing.application_signed(app_id)

  def send_payment_url(id), do: RentApplications.send_payment_url(id)

  def get_application_ledger(id), do: Ledgers.get_application_ledger(id)

  def create_bluemoon_lease_from_application(admin, id),
    do: BlueMoon.create_bluemoon_lease_from_application(admin, id)

  def notify_admins(%{application: app}, %AppCount.Core.ClientSchema{} = client_schema) do
    property =
      ClientSchema.new(client_schema.name, client_schema.attrs.property_id)
      |> AppCount.Properties.get_property()

    info_for_email = info_for_email(app, client_schema)

    ClientSchema.new(client_schema.name, client_schema.attrs.property_id)
    |> AppCount.Admins.admins_for(["Admin", "Agent"])
    |> Enum.each(fn admin ->
      AppCountCom.Applications.application_submitted(admin, property, info_for_email)
      # we sleep here because apparently otherwise it is too fast for AWS SES to handle
      AppCount.Core.Sleeper.sleep(1000)
    end)
  end

  ###### BEGINS FUNCTIONS FOR ADMIN EMAIL ######
  # Returns: %{id, applicants(string), customer_ledger(array)}
  def info_for_email(application, %AppCount.Core.ClientSchema{} = client_schema) do
    AppCount.Core.ClientSchema.new(client_schema.name, %{id: application.id})
    |> RentApplications.get_application_data()
    |> parse_data()
  end

  defp parse_data(%{occupants: persons, payments: payments} = data) do
    %{
      id: data.id,
      floor_plan: nil,
      applicants: lease_holders(persons),
      payment: payment_info_for_email(payments)
    }
  end

  defp lease_holders(persons) do
    persons
    |> Enum.filter(&(&1["status"] == "Lease Holder"))
    |> Enum.map(& &1["full_name"])
    |> Enum.join(", ")
  end

  defp payment_info_for_email(payments) do
    payment = Enum.at(payments, 0)

    %{
      id: payment["id"],
      total: payment["amount"],
      application_fee:
        find_amount_by_account_type(payment["receipts"], "Application Fees Income"),
      admin_fee: find_amount_by_account_type(payment["receipts"], "Administration Fees Income")
    }
  end

  defp find_amount_by_account_type(receipts, type) do
    case Enum.find(receipts, &(&1["account_name"] == type)) do
      nil -> Decimal.new(0)
      r -> r["amount"]
    end
  end

  ###### ENDS FUNCTIONS FOR ADMIN EMAIL ######

  def send_confirmation(
        %{application: app},
        %AppCount.Core.ClientSchema{} = client_schema,
        payment
      ) do
    emails =
      from(
        p in Person,
        where: p.application_id == ^app.id and p.status == "Lease Holder",
        select: p.email
      )
      |> Repo.all(prefix: client_schema.name)

    property =
      ClientSchema.new(client_schema.name, client_schema.attrs.property_id)
      |> AppCount.Properties.get_property()

    emails
    |> Enum.each(fn email ->
      AppCountCom.Applications.application_received(email, property, payment)
    end)
  end

  def document_data(document_id) do
    url =
      from(d in Document,
        join: u in assoc(d, :url_url),
        where: d.id == ^document_id,
        select: u.url
      )
      |> Repo.one()

    data =
      url
      |> HTTPoison.get!()
      |> Map.get(:body)

    filename =
      url
      |> URI.parse()
      |> Map.get(:path)
      |> Path.basename()

    {filename, data}
  end

  def send_application_summaries do
    Repo.all(AppCount.Admins.Admin)
    |> Enum.each(fn admin ->
      from_date = one_week_ago()
      applications = AppCount.RentApply.list_applications(admin, from_date)
      AppCountCom.Applications.application_summary(admin, from_date, applications)
    end)
  end

  defp one_week_ago() do
    AppCount.current_time()
    |> Timex.shift(days: -7)
    |> Timex.beginning_of_day()
  end

  def get_integration_credentials(admin) do
    property_ids = admin.property_ids

    screen_creds =
      from(
        p in AppCount.Properties.Processor,
        where: p.property_id in ^property_ids and not is_nil(p.keys) and p.type == "screening",
        select: p.property_id
      )
      |> Repo.all(prefix: admin.client_schema)

    lease_creds =
      from(
        p in AppCount.Properties.Processor,
        where: p.property_id in ^property_ids and not is_nil(p.keys) and p.type == "lease",
        select: p.property_id
      )
      |> Repo.all(prefix: admin.client_schema)

    %{
      screen_creds: screen_creds,
      lease_creds: lease_creds
    }
  end

  @spec screen_application(String.t() | integer, String.t() | integer, boolean()) :: [
          {:ok, %{}} | {:error, any}
        ]
  def screen_application(application_id, rent, instant_screen \\ false),
    do: Screening.screen_application(application_id, rent, instant_screen)

  @spec get_screening_status(String.t() | integer) :: [%{}]
  def get_screening_status(application_id), do: Screening.get_status(application_id)
end
