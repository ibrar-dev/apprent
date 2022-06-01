defmodule AppCount.Messaging.Utils.Mailings do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Messaging.Mailing
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def create_mailing(admin, %{"send_at" => send_at} = params) do
    decoded_send_at = Poison.decode!(send_at)

    case decoded_send_at["date"] do
      nil -> send_mail(params)
      _ -> create_scheduled_mailing(admin, params)
    end
  end

  def send_mail(
        %{
          "recipients" => recipients,
          "body" => body,
          "subject" => subject,
          "attachments" => attachments
        } = _
      ) do
    AppCount.Core.Tasker.start(fn ->
      Poison.decode!(recipients)
      |> Enum.each(fn r -> attach_property(r, subject, body, attachments) end)
    end)

    {:ok, %{}}
  end

  def send_mail(%{"recipients" => recipients, "body" => body, "subject" => subject} = _) do
    AppCount.Core.Tasker.start(fn ->
      Poison.decode!(recipients)
      |> Enum.each(fn r -> attach_property(r, subject, body, []) end)
    end)

    {:ok, %{}}
  end

  def send_mail(
        %{body: body, subject: subject, recipients: recipients, attachments: attachments} = _
      ) do
    AppCount.Core.Tasker.start(fn ->
      Enum.each(recipients, fn r -> attach_property(r, subject, body, attachments) end)
    end)

    {:ok, %{}}
  end

  def attach_property(
        %{"property_id" => property_id, "email" => email} = recipient,
        subject,
        body,
        attachments
      ) do
    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", property_id))
    parsed_body = parse_short_codes(body, recipient)

    AppCountCom.Messaging.send_individual_email(
      subject,
      parsed_body,
      attachments,
      email,
      property
    )
  end

  def create_scheduled_mailing(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        params
      ) do
    new_params =
      params
      |> Map.put("recipients", Poison.decode!(params["recipients"]))
      |> Map.merge(%{
        "sender" => admin.name,
        "property_ids" => get_property_ids(ClientSchema.new(client_schema, params["recipients"])),
        "send_at" => Poison.decode!(params["send_at"])
      })

    %Mailing{}
    |> Mailing.changeset(new_params)
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, r} -> schedule_next(r)
      e -> e
    end
  end

  def get_property_ids(recipients) do
    Poison.decode!(recipients)
    |> Enum.map(fn x -> x["property_id"] end)
    |> Enum.uniq()
  end

  def schedule_next(mailing) do
    next_run =
      Timex.parse!(mailing.send_at["date"], "{ISO:Extended:Z}")
      |> Timex.beginning_of_day()
      |> Timex.shift(minutes: mailing.send_at["time"])
      |> Timex.shift(hours: 5)
      |> Timex.to_unix()

    mailing
    |> Mailing.changeset(%{next_run: next_run})
    |> Repo.update()
  end

  def send_email_job() do
    start_time = AppCount.current_time() |> Timex.shift(minutes: -1) |> Timex.to_unix()
    end_time = AppCount.current_time() |> Timex.shift(minutes: 10) |> Timex.to_unix()

    from(
      m in Mailing,
      where: between(m.next_run, ^start_time, ^end_time),
      select: %{
        id: m.id,
        recipients: m.recipients,
        subject: m.subject,
        body: m.body,
        attachments: m.attachments
      }
    )
    |> Repo.all()
    |> Enum.each(fn x -> send_mail(x) end)
  end

  def parse_short_codes(body, recipient) do
    Regex.scan(~r/<a[^>]*>([^<]+)<\/a>/, body)
    |> Enum.reduce(body, fn x, acc ->
      replace_short_code(acc, List.first(x), List.last(x), recipient)
    end)
  end

  def replace_short_code(body, code, "@APPRENT_SC_FULL_NAME", %{"id" => id} = _) do
    full_name =
      from(
        t in AppCount.Tenants.Tenant,
        where: t.id == ^id,
        select: fragment("? || ' ' || ?", t.first_name, t.last_name),
        limit: 1
      )
      |> Repo.one()

    String.replace(body, code, full_name)
  end

  def replace_short_code(body, code, "@APPRENT_SC_FIRST_NAME", %{"id" => id} = _) do
    full_name =
      from(
        t in AppCount.Tenants.Tenant,
        where: t.id == ^id,
        select: t.first_name,
        limit: 1
      )
      |> Repo.one()

    String.replace(body, code, full_name)
  end

  def replace_short_code(body, code, "@APPRENT_SC_LAST_NAME", %{"id" => id} = _) do
    full_name =
      from(
        t in AppCount.Tenants.Tenant,
        where: t.id == ^id,
        select: t.last_name,
        limit: 1
      )
      |> Repo.one()

    String.replace(body, code, full_name)
  end

  def replace_short_code(body, code, "@APPRENT_SC_CURRENT_BALANCE", %{"id" => id} = _) do
    balance =
      AppCount.Accounts.Utils.AccountInfo.user_balance(id)
      |> Enum.reduce(Decimal.new(0), fn x, acc -> Decimal.add(x.balance, acc) end)
      |> Decimal.to_string()

    String.replace(body, code, "$#{balance}")
  end

  def replace_short_code(body, code, "@APPRENT_SC_PROPERTY_NAME", %{"property" => property} = _) do
    String.replace(body, code, property)
  end

  def replace_short_code(
        body,
        code,
        "@APPRENT_SC_PROPERTY_URL",
        %{"property_id" => property_id} = _
      ) do
    url =
      from(
        p in AppCount.Properties.Property,
        where: p.id == ^property_id,
        select: p.website,
        limit: 1
      )
      |> Repo.one()

    String.replace(body, code, url)
  end

  def replace_short_code(
        body,
        code,
        "@APPRENT_SC_PROPERTY_PHONE",
        %{"property_id" => property_id} = _
      ) do
    phone =
      from(
        p in AppCount.Properties.Property,
        where: p.id == ^property_id,
        select: p.phone,
        limit: 1
      )
      |> Repo.one()

    String.replace(body, code, phone)
  end

  def replace_short_code(body, code, "@APPRENT_SC_LATE_FEE", %{"property_id" => property_id} = _) do
    fee =
      from(
        p in AppCount.Properties.Property,
        join: s in assoc(p, :setting),
        where: p.id == ^property_id,
        select: fragment("? || ' ' || ?", s.late_fee_type, s.late_fee_amount),
        limit: 1
      )
      |> Repo.one()

    String.replace(body, code, fee)
  end

  def replace_short_code(body, code, "@APPRENT_SC_UNIT_NUMBER", %{"unit" => unit} = _) do
    String.replace(body, code, unit)
  end

  def replace_short_code(body, code, "@APPRENT_SC_TODAYS_DATE", _) do
    today = AppCount.current_time() |> Timex.format!("%m-%d-%Y", :strftime)
    String.replace(body, code, today)
  end

  def replace_short_code(body, _, _, _), do: body
end
