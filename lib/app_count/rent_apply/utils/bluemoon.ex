defmodule AppCount.RentApply.Utils.BlueMoon do
  alias AppCount.Repo
  alias AppCount.Properties
  alias AppCount.Leases
  alias AppCount.RentApply.RentApplication
  import Ecto.Query
  import AppCount.EctoExtensions

  def create_bluemoon_lease_from_application(admin, application_id) do
    params =
      from(
        a in RentApplication,
        join: f in assoc(a, :form),
        join: p in assoc(a, :persons),
        join: pr in assoc(a, :property),
        where: a.id == ^application_id,
        select: %{
          form: f,
          approval_params: a.approval_params,
          property_id: a.property_id,
          persons:
            jsonize(p, [:id, :full_name, :status, :email, :home_phone, :cell_phone, :work_phone]),
          property_phone: pr.phone,
          application_id: a.id
        },
        group_by: [a.id, pr.id, f.id]
      )
      |> Repo.one()
      |> Map.put(:admin, admin)

    credentials =
      AppCount.Leases.Utils.BlueMoon.property_credentials(%{property_id: params.property_id})

    {lease_params, custom} = convert_to_bluemoon_format(params)

    create_params = %BlueMoon.Requests.CreateLease.Parameters{
      property_id: credentials.property_id,
      lease_params: lease_params,
      custom_params: custom
    }

    case BlueMoon.create_lease(credentials, create_params) do
      {:ok, form_id} ->
        Leases.update_form(params.form.id, %{form_id: form_id, admin: admin.name})

        sig_params =
          params
          |> Map.merge(%{bluemoon_id: form_id, residents: residents(params.persons)})

        Leases.request_bluemoon_signature(credentials, sig_params)

      e ->
        e
    end
  end

  def convert_to_bluemoon_format(%{approval_params: approval, form: form, persons: persons}) do
    {address, number} = get_unit_address(approval.unit_id)
    {total, prorated} = calculate_rent(approval)

    params =
      [
        {"ADDRESS", address},
        {"UNIT-NUMBER", number},
        {"LEASE-BEGIN-DATE", format_date!(approval.start_date)},
        {"LEASE-END-DATE", format_date!(approval.end_date)},
        {"DATE-OF-LEASE", format_date!(form.lease_date)},
        {"RENT", total},
        {"PRORATED-RENT", prorated},
        {"NUMBER-OF-APARTMENT-KEYS", form.unit_keys},
        {"NUMBER-OF-MAIL-KEYS", form.mail_keys},
        {"NUMBER-OF-OTHER-KEYS", form.other_keys},
        {"RENTERS-INSURANCE-PROVIDER", form.insurance_company},
        {"WASHER-DRYER-FEE", "#{form.washer_rent}"},
        {"WASHER-DRYER-FULL-SIZE", convert_bool(form.washer_type == "Full Size")},
        {"WASHER-DRYER-STACKABLE", convert_bool(form.washer_type == "Stackable")},
        {"DRYER-MODEL-SERIAL-NUMBER", form.dryer_serial},
        {"WASHER-MODEL-SERIAL-NUMBER", form.washer_serial},
        {"REMOTE-CARD-CODE-ADDENDUM-CARD", convert_bool(form.gate_access_card)},
        {"REMOTE-CARD-CODE-ADDENDUM-REMOTE", convert_bool(form.gate_access_remote)},
        {"REMOTE-CARD-CODE-ADDENDUM-CODE", convert_bool(form.gate_access_code)},
        {"REMOTE-CARD-CODE-ADDENDUM-LOST-REMOTE", convert_bool(form.lost_remote_fee)},
        {"REMOTE-CARD-CODE-ADDENDUM-LOST-CARD", convert_bool(form.lost_card_fee)},
        {"REMOTE-CARD-CODE-ADDENDUM-CODE-CHANGE", convert_bool(form.code_change_fee)},
        {"EARLY-TERMINATION-FEE", "#{form.buy_out_fee}"},
        {"EARLY-TERMINATION-TOTAL-FEE", "#{form.concession_fee}"},
        {"ADDENDUM-RENT-CONCESSION-ONE-TIME", convert_bool(!!form.one_time_concession)},
        {"ADDENDUM-RENT-CONCESSION-ONE-TIME-AMOUNT", "#{form.one_time_concession}"},
        {"ADDENDUM-RENT-CONCESSION-ONE-TIME-MONTHS", Enum.join(form.concession_months, ",")},
        {"ADDENDUM-RENT-CONCESSION-MONTHLY-DISCOUNT", convert_bool(!!form.monthly_discount)},
        {"ADDENDUM-RENT-CONCESSION-AMOUNT", form.monthly_discount},
        {"ADDENDUM-RENT-CONCESSION-OTHER-DISCOUNT", convert_bool(!!form.other_discount)},
        {"ADDENDUM-RENT-CONCESSION-DESCRIPTION", form.other_discount},
        {"BED-BUG-ADDENDUM-INFESTATION-DISCLOSURE", form.bug_disclosure},
        {"BED-BUG-ADDENDUM-INFESTATION", form.bug_infestation},
        {"BED-BUG-ADDENDUM-INSPECTION", form.bug_inspection},
        get_security(form)
      ] ++ holders_list(persons) ++ other_washer_values(form) ++ fitness_numbers(form)

    custom = [
      {"SMART-FEE", "#{form.smart_fee}"},
      {"WASTE-FEE", "#{form.waste_cost}"}
    ]

    {params, custom}
  end

  defp fitness_numbers(lease) do
    {numbers, _} =
      Enum.reduce(
        lease.fitness_card_numbers,
        {[], 1},
        fn num, {entries, index} ->
          {[{"COMMUNITY-FITNESS-CENTER-CARD-#{index}", num} | entries], index + 1}
        end
      )

    numbers
  end

  defp get_unit_address(nil), do: %{address: nil, number: nil}

  defp get_unit_address(unit_id) do
    %{address: a, number: n} = Repo.get(Properties.Unit, unit_id)
    {a["street"], n}
  end

  defp calculate_rent(%{start_date: start_date, charges: charges} = _) do
    total =
      charges
      |> Enum.reduce(0, fn c, acc -> c["amount"] + acc end)
      |> AppCount.Decimal.Float.to_printable()

    days = Date.days_in_month(start_date)
    {day, _} = Integer.parse(Timex.format!(start_date, "{D}"))
    # includes fix for broken Decimal stuff :(
    prorated = Float.ceil(total / days * (days - day + 1) - 0.0000000000001, 2)
    {total, AppCount.Decimal.Float.to_printable(prorated)}
  end

  defp holders_list(persons) do
    {result, _, _} =
      Enum.reduce(
        persons,
        {[], 1, 1},
        fn
          %{"status" => "Lease Holder"} = person, {strings, r_index, o_index} ->
            {strings ++ [{"RESIDENT-#{r_index}", person["full_name"]}], r_index + 1, o_index}

          person, {strings, r_index, o_index} ->
            {strings ++ [{"OCCUPANT-#{o_index}", person["full_name"]}], r_index, o_index + 1}
        end
      )

    result
  end

  defp get_security(%{"val" => ""}) do
    {"SPECIAL-PROVISIONS",
     "All communication with Agent for Owner must be conducted via writing."}
  end

  defp get_security(%{deposit_type: "deposit", deposit_value: val}) do
    {converted_val, _} = Float.parse(val)
    {"SECURITY-DEPOSIT", converted_val}
  end

  defp get_security(%{deposit_type: "bond", deposit_value: val}) do
    {
      "SPECIAL-PROVISIONS",
      "All communication with Agent for Owner must be conducted via writing. Non Refundable Bond - $#{
        val
      }"
    }
  end

  defp get_security(%{deposit_value: val}) do
    {
      "SPECIAL-PROVISIONS",
      "All communication with Agent for Owner must be conducted via writing. ePremium Account Number - #{
        val
      }"
    }
  end

  defp other_washer_values(%{washer_type: w}) when w in ["Full Stack", "Stackable"] do
    [{"WASHER-DRYER-OTHER", "F"}]
  end

  defp other_washer_values(%{washer_type: w}) do
    [{"WASHER-DRYER-OTHER-DESC", w}, {"WASHER-DRYER-OTHER", "T"}]
  end

  defp convert_bool(true), do: "T"
  defp convert_bool(false), do: "F"

  defp format_date!(date), do: Timex.format!(date, "{M}/{D}/{YYYY}")

  defp residents(persons) do
    persons
    |> Enum.filter(&(&1["status"] == "Lease Holder"))
    |> Enum.map(fn person ->
      %BlueMoon.Requests.RequestSignature.Person{
        name: person["full_name"],
        email: email_address(person),
        phone: person["home_phone"] || person["cell_phone"] || person["work_phone"]
      }
    end)
  end

  if Mix.env() == :prod do
    defp email_address(person), do: person["email"]
  else
    defp email_address(_), do: Application.get_env(:app_count, :test_email)
  end
end
