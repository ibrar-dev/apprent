defmodule AppCount.RentApply.Utils.RentApplications do
  alias AppCount.Admins
  alias AppCount.Repo
  alias AppCount.Properties
  alias AppCount.RentApply
  alias AppCount.ShortCodes
  alias AppCount.Ledgers.Payment
  alias AppCount.RentApply.Document
  alias AppCount.RentApply.EmergencyContact
  alias AppCount.RentApply.Employment
  alias AppCount.RentApply.History
  alias AppCount.RentApply.Income
  alias AppCount.RentApply.Memo
  alias AppCount.RentApply.MoveIn
  alias AppCount.RentApply.Person
  alias AppCount.RentApply.Pet
  alias AppCount.RentApply.RentApplication
  alias AppCount.RentApply.Vehicle
  alias AppCount.RentApply.Forms.SavedForm
  alias AppCount.Core.RentApplicationTopic
  alias AppCount.Core.ClientSchema

  alias Ecto.Multi
  use AppCount.Decimal
  import Ecto.Query
  import AppCount.RentApply.Queries

  def create_document(params) do
    %Document{}
    |> Document.changeset(params)
    |> Repo.insert()
  end

  def create_memo(params, admin) do
    %Memo{}
    |> Memo.changeset(Map.merge(params, %{"admin_id" => admin.id}))
    |> Repo.insert()
  end

  def random_applicant_id(property_id) do
    alias AppCount.RentApply.Person

    from(
      p in Person,
      join: a in assoc(p, :application),
      order_by: fragment("RANDOM()"),
      limit: 1,
      where: a.property_id == ^property_id,
      select: p.id
    )
    |> Repo.one()
  end

  def letter_contents(html, params) do
    ShortCodes.parse_short_codes(html, params, :applicants)
  end

  defp handle_concatenate(acc) do
    Enum.at(acc, -1)
    |> case do
      {:ok, _} -> {:ok, AppCount.Data.concatenate_pdfs(Enum.map(acc, fn {:ok, b} -> b end))}
      {:error, e} -> {:error, e}
    end
  end

  def generate_rent_verify_form(params, generate_preview_fn) do
    %{verification_form: vf} = Repo.get_by(Properties.Setting, property_id: params["property_id"])

    Enum.reduce_while(params["person_id"], [], fn a, acc ->
      case generate_preview_fn.(vf, %{person_id: a}) do
        {:ok, binary} -> {:cont, acc ++ [{:ok, binary}]}
        {:error, _} -> {:halt, acc ++ [{:error, "There was an error generating a form."}]}
      end
    end)
    |> handle_concatenate
  end

  def list_applications(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        property_id,
        start_date,
        end_date
      ) do
    Admins.property_ids_for(ClientSchema.new(client_schema, admin))
    |> administration_query(Enum.any?(admin.roles, &String.match?(&1, ~r/Admin/)))
    |> where([r], r.property_id == ^property_id)
    |> where([r], r.inserted_at >= ^parse_date(start_date))
    |> where([r], r.inserted_at <= ^parse_date(end_date))
    |> Repo.all(prefix: client_schema)
  end

  def list_applications(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        property_id: property_id
      ) do
    Admins.property_ids_for(ClientSchema.new(client_schema, admin))
    |> administration_query(Enum.any?(admin.roles, &String.match?(&1, ~r/Admin/)))
    |> where([r], r.property_id == ^property_id)
    |> Repo.all(prefix: client_schema)
  end

  def list_applications(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, from_date) do
    Admins.property_ids_for(ClientSchema.new("dasmen", admin))
    |> administration_query(Enum.any?(admin.roles, &String.match?(&1, ~r/Admin/)))
    |> where([r], r.inserted_at > ^from_date)
    |> Repo.all(prefix: client_schema)
  end

  def list_saved_forms(
        %AppCountAuth.Users.Admin{client_schema: client_schema, property_ids: admin_property_ids},
        %{
          property_id: property_id
        }
      ) do
    date = ~D[2020-07-07]
    {:ok, datetime} = NaiveDateTime.new(date, ~T[00:00:00])

    from(
      r in SavedForm,
      where: r.property_id in ^admin_property_ids,
      where: r.inserted_at >= ^datetime,
      left_join: app in RentApply.RentApplication,
      on: r.id == app.saved_form_id,
      where: is_nil(app.saved_form_id),
      select: %{
        id: r.id,
        email: r.email,
        name: r.name,
        lang: r.lang,
        form_summary: r.form_summary,
        property_id: r.property_id,
        inserted_at: r.inserted_at,
        updated_at: r.updated_at,
        start_time: r.start_time
      },
      order_by: [desc: r.updated_at]
    )
    |> where([r], r.property_id == ^property_id)
    |> Repo.all(prefix: client_schema)
  end

  def get_property_applications(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_id
      }) do
    from(
      r in RentApplication,
      join: p in assoc(r, :persons),
      left_join: u in Properties.Unit,
      on: u.id == fragment("(approval_params->>'unit_id')::integer"),
      select: %{
        id: r.id,
        name: p.full_name,
        property_id: r.property_id,
        approval_params: type(r.approval_params, :map),
        unit: %{
          id: u.id,
          number: u.number
        }
      },
      where: r.property_id == ^property_id,
      where: p.status == "Lease Holder"
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_applicants_for_payments(property_id) do
    from(
      r in RentApplication,
      join: p in assoc(r, :persons),
      join: mi in assoc(r, :move_in),
      left_join: miu in assoc(mi, :unit),
      left_join: u in Properties.Unit,
      on: u.id == fragment("(approval_params->>'unit_id')::integer"),
      left_join: t in assoc(r, :tenant),
      where: p.status == "Lease Holder" and r.property_id == ^property_id,
      where: is_nil(r.declined_on) or r.status != "declined",
      select: %{
        id: r.id,
        name: p.full_name,
        property_id: r.property_id,
        approval_params: type(r.approval_params, :map),
        status: r.status,
        unit: u.number,
        move_in: %{
          id: mi.id,
          unit_id: mi.unit_id,
          expected_move_in: mi.expected_move_in,
          unit: miu.number
        },
        tenant_id: t.id
      },
      order_by: [desc: :inserted_at]
    )
    |> Repo.all()
    |> Enum.filter(&is_nil(&1.tenant_id))
  end

  def update_application(id, params) do
    Repo.get(RentApplication, id)
    |> RentApplication.changeset(params)
    |> Repo.update()
  end

  def get_applications_for_property(property_code) do
    prop = Properties.get_property(code: property_code)

    from(
      r in RentApplication,
      where: r.property_id == ^prop.id,
      order_by: [
        desc: r.inserted_at
      ]
    )
    |> Repo.all()
  end

  def get_application_data(%AppCount.Core.ClientSchema{name: name, attrs: attrs}) do
    application_data(attrs.id)
    |> Repo.one(prefix: name)
    |> decrypt_ssns()
    |> resolve_document_urls()
  end

  def get_application(id) do
    Repo.get(RentApplication, id)
    |> application()
  end

  def get_application(id, property_code, _admin) do
    prop = Properties.get_property(code: property_code)

    Repo.get_by(RentApplication, id: id, property_id: prop.id)
    |> application
  end

  def application(%RentApplication{} = appl) do
    appl
    |> Repo.preload([
      :persons,
      :emergency_contacts,
      :histories,
      :vehicles,
      :income,
      :employments,
      :documents,
      :pets
    ])
    |> Repo.preload(move_in: :unit, property: :setting)
  end

  def process_application(%AppCount.Core.ClientSchema{name: schema_name, attrs: attrs}, params) do
    property_id = attrs.property_id

    Multi.new()
    |> Multi.insert(
      :application,
      application_cs(
        property_id,
        Map.take(params, [
          "payment_id",
          "device_id",
          "prospect_id",
          "lang",
          "start_time",
          "customer_ledger_id",
          "saved_form_id",
          "terms_and_conditions"
        ])
      )
    )
    |> Multi.run(
      :payment,
      fn _, cs ->
        Repo.get(Payment, params["payment_id"])
        |> Payment.changeset(%{application_id: cs.application.id})
        |> Repo.update()
      end
    )
    |> Multi.run(:occupants, fn _, cs -> has_many_relation(cs, params["occupants"], Person) end)
    |> Multi.run(:move_in, fn _, cs -> move_in(cs, params["move_in"]) end)
    |> Multi.run(:income, fn _, cs -> income(cs, params["income"]) end)
    |> Multi.run(
      :emergency_contacts,
      fn _, cs -> has_many_relation(cs, params["emergency_contacts"], EmergencyContact) end
    )
    |> Multi.run(:pets, fn _, cs -> has_many_relation(cs, params["pets"], Pet) end)
    |> Multi.run(:vehicles, fn _, cs -> has_many_relation(cs, params["vehicles"], Vehicle) end)
    |> Multi.run(
      :employments,
      fn _, cs ->
        has_many_relation(cs, params["employments"], Employment)
      end
    )
    |> Multi.run(:histories, fn _, cs -> has_many_relation(cs, params["histories"], History) end)
    # |> Multi.run(:documents, fn _, cs -> has_many_relation(cs, params["documents"], Document) end)
    |> Repo.transaction(prefix: schema_name)
    # TODO |> publish_application_created()
    |> add_documents(params["documents"])

    #    |> maybe_screen()
  end

  def publish_application_created({:ok, %{application: application}} = result) do
    #
    # WIP, TODO, FIXME  David or Yousef need to provide items with accounts for recording the rent_application
    #
    item01 = %{
      description: "Thing One",
      amount_in_cents: 1200,
      account_id: 123
    }

    item02 = %{
      description: "Thing Two",
      amount_in_cents: 1200,
      account_id: 456
    }

    line_items = [item01, item02]

    content = %{line_items: line_items, account_id: 999}

    _domain_event = RentApplicationTopic.created(application.id, content, __MODULE__)
    result
  end

  def publish_application_created(error_result) do
    error_result
  end

  def add_documents(result_tuple, documents \\ [])

  def add_documents({:ok, %{application: application}} = result, documents) do
    documents
    |> Enum.each(fn document ->
      params = %{
        application_id: application.id,
        url: document["url"],
        type: document["type"]
      }

      create_document(params)
    end)

    result
  end

  def add_documents(some_error, _documents) do
    some_error
  end

  def maybe_screen({:ok, %{application: app, move_in: move_in}} = result) do
    if Properties.can_instant_screen(app.property_id) &&
         (move_in.unit_id || move_in.floor_plan_id) do
      cond do
        is_nil(move_in.unit_id) ->
          # TODO:SCHEMA add schema proper
          Properties.floor_plan_market_rent(ClientSchema.new("dasmen", move_in.floor_plan_id))

        is_nil(move_in.floor_plan_id) ->
          Properties.market_rent(move_in.unit_id)
      end
      |> instascreen(result)
    else
      result
    end
  end

  def maybe_screen(r), do: r

  defp instascreen(rent, {:ok, %{application: app}} = result) do
    if Decimal.cmp(rent, 0) == :gt do
      AppCount.Core.Tasker.start(fn -> RentApply.screen_application(app.id, rent) end)
      result
    else
      result
    end
  end

  def full_update_application(id, params) do
    update_section(id, Person, params["occupants"])
    update_section(id, EmergencyContact, params["emergency_contacts"])
    update_section(id, Pet, params["pets"])
    update_section(id, Vehicle, params["vehicles"])
    update_section(id, Employment, params["employments"])
    update_section(id, History, params["histories"])
    update_section(id, Income, params["income"])
    update_section(id, MoveIn, params["move_in"])
  end

  def update_status({:e, error}), do: {:ok, error}

  def update_status({:ok, application}),
    do: update_application(application.id, %{status: "Moved In"})

  ## END FUNCTIONS TO MOVE SOMEONE IN FROM APP

  def send_payment_url(id) do
    app = Repo.get(RentApply.RentApplication, id)

    {:ok, crypt} = AppCount.Crypto.LocalCryptoServer.encrypt("#{id}")

    encoded_crypt =
      crypt
      |> URI.encode_www_form()

    url = "#{AppCount.namespaced_url("application")}/payment/#{encoded_crypt}"

    first_person =
      from(
        p in AppCount.RentApply.Person,
        where: p.application_id == ^id and p.status == "Lease Holder",
        limit: 1,
        select: %{
          id: p.id,
          name: p.full_name,
          email: p.email
        }
      )
      |> Repo.one()

    property = Properties.get_property(ClientSchema.new("dasmen", app.property_id))
    AppCountCom.Applications.send_payment_url(property, url, first_person)
  end

  ## END FUNCTIONS FOR SENDING DAILY REPORT

  defp application_cs(property_id, params) do
    RentApplication.changeset(%RentApplication{}, Map.put(params, "property_id", property_id))
  end

  defp has_many_relation(cs, raw_data, module) do
    raw_data
    |> Enum.reduce_while({:ok, cs}, &belongs_to(&1, &2, cs, module))
  end

  defp belongs_to(%{"occupant_index" => index} = item, {:ok, _}, cs, module) do
    index = occ_index(index)

    persons =
      Repo.preload(cs.application, :persons)
      |> Map.get(:persons)

    person = Enum.at(persons, index)

    result =
      module.changeset(
        struct(module, %{}),
        Map.merge(item, %{"application_id" => cs.application.id, "person_id" => person.id})
      )
      |> Repo.insert()

    {:cont, result}
  end

  defp belongs_to(item, {:ok, _}, cs, module) do
    result =
      module.changeset(
        struct(module, %{}),
        Map.put(item, "application_id", cs.application.id)
      )
      |> Repo.insert()

    {:cont, result}
  end

  defp belongs_to(_item, {:error, error}, _, _), do: {:halt, {:error, error}}

  defp move_in(%{application: %RentApplication{} = application}, params) do
    MoveIn.changeset(%MoveIn{}, Map.put(params, "application_id", application.id))
    |> Repo.insert()
  end

  defp income(%{application: %RentApplication{}} = p, nil), do: {:ok, p}
  defp income(%{application: %RentApplication{}} = p, %{"salary" => 0}), do: {:ok, p}

  defp income(%{application: %RentApplication{} = application}, params) do
    %Income{}
    |> Income.changeset(Map.put(params, "application_id", application.id))
    |> Repo.insert()
  end

  defp occ_index(nil), do: 0
  defp occ_index(index) when is_binary(index), do: occ_index(String.to_integer(index))
  defp occ_index(index) when is_integer(index), do: index - 1

  defp update_section(_, _, nil), do: nil

  defp update_section(application_id, module, params) when is_list(params) do
    from(
      m in module,
      where:
        m.id not in ^Enum.reduce(
          params,
          [],
          fn i, s ->
            if i["id"] == "", do: s, else: s ++ [i["id"]]
          end
        ),
      where: m.application_id == ^application_id
    )
    |> Repo.delete_all()

    Enum.each(params, &do_update_section(application_id, module, &1))
  end

  defp update_section(id, module, %{"present" => true} = i), do: do_update_section(id, module, i)

  defp update_section(application_id, module, %{"id" => ""}) do
    from(m in module, where: m.application_id == ^application_id)
    |> Repo.delete_all()
  end

  defp update_section(application_id, module, params) do
    unless params["id"] == "" do
      from(
        m in module,
        where: m.id != ^params["id"],
        where: m.application_id == ^application_id
      )
      |> Repo.delete_all()
    end

    do_update_section(application_id, module, params)
  end

  defp do_update_section(application_id, module, %{"id" => id} = item)
       when is_nil(id) or id == "" do
    p = Map.put(item, "application_id", application_id)

    struct(module)
    |> module.changeset(p)
    |> Repo.insert()
  end

  defp do_update_section(_, module, params) do
    Repo.get(module, params["id"])
    |> module.changeset(params)
    |> Repo.update()
  end

  defp decrypt_ssns(%{occupants: occ} = data) do
    Map.put(
      data,
      :occupants,
      Enum.map(occ, &Map.put(&1, "ssn", extract_ssn(&1["ssn"])))
    )
  end

  defp extract_ssn(crypted) do
    result = AppCount.Crypto.LocalCryptoServer.decrypt(crypted)

    case result do
      {:ok, ssn} -> ssn
      _anything_else -> "Missing"
    end
  end

  defp resolve_document_urls(%{documents: docs} = data) do
    Map.put(data, :documents, Enum.map(docs, &convert_url/1))
  end

  defp convert_url(doc) do
    {:ok, url} = AppCount.Data.UploadURL.URL.load(doc["url"])
    Map.put(doc, "url", url)
  end

  defp parse_date(date) when is_binary(date) do
    date
    |> Timex.parse!("{YYYY}-{M}-{D}")
    |> Timex.end_of_day()
  end
end
