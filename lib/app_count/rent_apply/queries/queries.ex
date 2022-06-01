defmodule AppCount.RentApply.Queries do
  import Ecto.Query
  import AppCount.EctoExtensions

  alias AppCount.RentApply.RentApplication
  alias AppCount.RentApply.Person
  alias AppCount.RentApply.Pet
  alias AppCount.RentApply.Vehicle
  alias AppCount.RentApply.MoveIn
  alias AppCount.RentApply.History
  alias AppCount.RentApply.EmergencyContact
  alias AppCount.RentApply.Employment
  alias AppCount.RentApply.Income

  def administration_query(property_ids, full) do
    full = "#{full}"

    from(
      r in RentApplication,
      left_join: pe in assoc(r, :persons),
      left_join: scr in assoc(pe, :screening),
      left_join: d in assoc(r, :documents),
      left_join: pr in assoc(r, :property),
      left_join: s in assoc(pr, :setting),
      left_join: m in assoc(r, :move_in),
      left_join: u in assoc(m, :unit),
      left_join: f in assoc(u, :features),
      left_join: payments in subquery(payments_query()),
      on: payments.application_id == r.id,
      left_join: pet in assoc(r, :pets),
      select: %{
        id: r.id,
        full: ^full,
        approval_params: type(r.approval_params, :map),
        status: r.status,
        inserted_at: r.inserted_at,
        declined_on: r.declined_on,
        declined_reason: r.declined_reason,
        declined_by: r.declined_by,
        bluemoon_lease_id: r.bluemoon_lease_id,
        device_id: r.device_id,
        is_conditional: r.is_conditional,
        move_in: %{
          id: m.id,
          unit_id: m.unit_id,
          expected_move_in: m.expected_move_in
        },
        persons:
          jsonize(
            pe,
            [
              :id,
              :full_name,
              :status,
              :email,
              :home_phone,
              :work_phone,
              :cell_phone,
              {:screening_decision, scr.decision},
              {:screening_status, scr.status},
              {:screening_url, scr.url},
              {:screening_id, scr.id}
            ]
          ),
        pets: jsonize(pet, [:id]),
        documents: jsonize(d, [:id, :type]),
        property: jsonize_one(pr, [:name, :id]),
        unit: %{
          id: u.id,
          number: u.number,
          default_price: fragment("? + (? * ?)", sum(f.price), s.area_rate, u.area)
        },
        payments:
          jsonize(payments, [
            :id,
            :amount,
            :inserted_at,
            :description,
            :transaction_id,
            :memo,
            :receipts
          ])
      },
      group_by: [u.id, r.id, s.area_rate, pr.id, m.id],
      where: r.property_id in ^property_ids,
      where: is_nil(f.stop_date),
      order_by: [
        desc: r.inserted_at
      ]
    )
  end

  def application_data(id) do
    from(
      rent_application in RentApplication,
      left_join: tenant in assoc(rent_application, :tenant),
      left_join: tenancy in assoc(tenant, :tenancies),
      left_join: person in assoc(rent_application, :persons),
      left_join: emergency_contact in assoc(rent_application, :emergency_contacts),
      left_join: history in assoc(rent_application, :histories),
      left_join: employment in assoc(rent_application, :employments),
      left_join: document in assoc(rent_application, :documents),
      left_join: url in assoc(document, :url_url),
      left_join: property in assoc(rent_application, :property),
      left_join: logo in assoc(property, :logo_url),
      left_join: icon in assoc(property, :icon_url),
      left_join: setting in assoc(property, :setting),
      left_join: move_in in assoc(rent_application, :move_in),
      left_join: unit in assoc(move_in, :unit),
      left_join: pet in assoc(rent_application, :pets),
      left_join: vehicle in assoc(rent_application, :vehicles),
      left_join: income in assoc(rent_application, :income),
      left_join: memo in assoc(rent_application, :memos),
      left_join: admin in assoc(memo, :admin),
      left_join: payments in subquery(payments_query()),
      on: payments.application_id == rent_application.id,
      where: rent_application.id == ^id,
      select: %{
        id: rent_application.id,
        tenancy_id: max(tenancy.id),
        terms_and_conditions: rent_application.terms_and_conditions,
        occupants: jsonize(person, schema_fields(Person)),
        pets: jsonize(pet, schema_fields(Pet)),
        histories: jsonize(history, schema_fields(History)),
        move_in: jsonize_one(move_in, schema_fields(MoveIn)),
        emergency_contacts: jsonize(emergency_contact, schema_fields(EmergencyContact)),
        vehicles: jsonize(vehicle, schema_fields(Vehicle)),
        employments: jsonize(employment, schema_fields(Employment)),
        income: jsonize_one(income, schema_fields(Income)),
        documents: jsonize(document, [:id, :type, {:url, url.url}]),
        memos: jsonize(memo, [:id, :note, :admin_id, :inserted_at, {:admin_name, admin.name}]),
        payments:
          jsonize(payments, [
            :id,
            :amount,
            :inserted_at,
            :description,
            :transaction_id,
            :memo,
            :receipts
          ]),
        property:
          merge(
            map(property, ^AppCount.Properties.Property.__schema__(:fields)),
            %{
              icon: icon.url,
              logo: logo.url,
              applicant_info_visible: setting.applicant_info_visible
            }
          ),
        unit: unit.number,
        inserted_at: rent_application.inserted_at
      },
      group_by: [
        rent_application.id,
        property.id,
        icon.url,
        logo.url,
        unit.id,
        setting.applicant_info_visible
      ]
    )
  end

  def full_application(property_ids) do
    from(
      r in RentApplication,
      preload: [
        :persons,
        :emergency_contacts,
        :histories,
        :employments,
        :move_in,
        :vehicles,
        :income,
        :documents,
        :pets,
        :property,
        :payment,
        :admin_payment
      ],
      where: r.property_id in ^property_ids,
      order_by: [
        desc: r.inserted_at
      ]
    )
  end

  # Payments now have a customer ledger which have charges which have a charge_code
  def payments_query() do
    from(
      p in AppCount.Ledgers.Payment,
      join: cl in assoc(p, :customer_ledger),
      join: charges in assoc(cl, :charges),
      join: charge_code in assoc(charges, :charge_code),
      select: %{
        id: p.id,
        amount: p.amount,
        inserted_at: p.inserted_at,
        receipts: jsonize(charges, [:id, :amount, {:account_name, charge_code.name}]),
        application_id: p.application_id,
        description: p.description,
        transaction_id: p.transaction_id,
        memo: p.memo
      },
      where: not is_nil(p.application_id),
      group_by: [p.id],
      order_by: :inserted_at
    )
  end
end
