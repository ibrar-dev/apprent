defmodule AppCount.ShortCodes.Applicants do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.RentApply
  alias AppCount.Properties.PropertyRepo

  def parse_short_codes(body, %{person_id: person_id}) do
    AppCount.ShortCodes.Parser.parse_html(body, fn code -> replace_short_code(code, person_id) end)
  end

  defp property_query(person_id) do
    from(
      person in RentApply.Person,
      join: a in assoc(person, :application),
      join: p in assoc(a, :property),
      where: person.id == ^person_id,
      limit: 1
    )
  end

  ##### GENERAL #####
  defp replace_short_code("CURRENT_DATE", _id), do: AppCount.current_date()

  defp replace_short_code("START_CURRENT_MONTH", _id) do
    AppCount.current_date()
    |> Timex.beginning_of_month()
  end

  defp replace_short_code("CURRENT_DATE_TIME", _id), do: AppCount.current_time()

  ##### ^GENERAL #####

  ##### PROPERTY #####

  defp replace_short_code("PROPERTY_NAME", id) do
    property_query(id)
    |> select([_, _, p], p.name)
    |> Repo.one()
  end

  defp replace_short_code("PROPERTY_ADDRESS", id) do
    address =
      property_query(id)
      |> select([_, _, p], p.address)
      |> Repo.one()

    address["street"]
  end

  defp replace_short_code("PROPERTY_ADDRESS_FULL", id) do
    property =
      property_query(id)
      |> select([_, _, p], p)
      |> Repo.one()

    "#{property.address["street"]}, #{property.address["city"]}, #{property.address["state"]} #{
      property.address["zip"]
    }"
  end

  defp replace_short_code("PROPERTY_ADDRESS_REMAINING", id) do
    property =
      property_query(id)
      |> select([_, _, p], p)
      |> Repo.one()

    "#{property.address["city"]}, #{property.address["state"]} #{property.address["zip"]}"
  end

  defp replace_short_code("PROPERTY_WEBSITE", id) do
    property_query(id)
    |> select([_, _, p], p.website)
    |> Repo.one()
  end

  defp replace_short_code("PROPERTY_PHONE", id) do
    property_query(id)
    |> select([_, _, p], p.phone)
    |> Repo.one()
  end

  defp replace_short_code("PROPERTY_GROUP_EMAIL", id) do
    property_query(id)
    |> select([_, _, p], p.group_email)
    |> Repo.one()
  end

  defp replace_short_code("PROPERTY_LOGO", _id) do
    #    property_query(id)
    #    |> select([_, p], p.group_email)
    #    |> Repo.one
  end

  defp replace_short_code("PROPERTY_APP_FEE", id) do
    property_id =
      property_query(id)
      |> select([_, _, p], p.id)
      |> Repo.one()

    setting = PropertyRepo.get(property_id) |> PropertyRepo.property_settings()
    setting.application_fee
  end

  defp replace_short_code("PROPERTY_ADMIN_FEE", id) do
    property_id =
      property_query(id)
      |> select([_, _, p], p.id)
      |> Repo.one()

    setting = PropertyRepo.get(property_id) |> PropertyRepo.property_settings()
    setting.admin_fee
  end

  defp replace_short_code("PROPERTY_NOTICE_PERIOD", id) do
    property_id =
      property_query(id)
      |> select([_, _, p], p.id)
      |> Repo.one()

    setting = PropertyRepo.get(property_id) |> PropertyRepo.property_settings()
    setting.notice_period
  end

  defp replace_short_code("PROPERTY_GRACE_PERIOD", id) do
    property_id =
      property_query(id)
      |> select([_, _, p], p.id)
      |> Repo.one()

    setting = PropertyRepo.get(property_id) |> PropertyRepo.property_settings()
    setting.grace_period
  end

  defp replace_short_code("PROPERTY_LATE_FEE", id) do
    property_id =
      property_query(id)
      |> select([_, _, p], p.id)
      |> Repo.one()

    setting = PropertyRepo.get(property_id) |> PropertyRepo.property_settings()
    setting.late_fee_amount
  end

  ##### ^PROPERTY #####

  ##### PERSON #####
  defp replace_short_code("PERSON_NAME", person_id) do
    Repo.get(RentApply.Person, person_id).full_name
  end

  defp replace_short_code("SIGN_DATE_TIME", person_id) do
    Repo.get(RentApply.Person, person_id).inserted_at
  end

  defp replace_short_code("SIGN_DATE", person_id) do
    Repo.get(RentApply.Person, person_id).inserted_at
    |> Timex.format!("{WDfull}, {Mfull} {D} {YYYY}")
  end

  defp replace_short_code("SIGN_TIME", person_id) do
    Repo.get(RentApply.Person, person_id).inserted_at
    |> Timex.format!("{h12}:{m}{AM}")
  end

  ##### ^PERSON #####
end
