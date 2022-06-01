defmodule AppCount.Support.PropertyBuilder do
  @moduledoc """
  PropertyBuilder lets you setup the DB in a bottoms-up manner.
  In the typical factory approache you say insert(:something), and it automatically builds all the things something depends on.
  This hides the details and makes it hard to modify them.

  PropertyBuilder exposes the dependencies explicityly in the arguments of the function for add_somthing()
  For example:  def add_permission(%Builder{req: %{region: region, admin: admin}} = builder, extra \\ []) do
  This makes it clear that a **Permission** requires a **Region** and an **Admin**
  You will need to call __add_permission()__ and __add_admin()__  before calling __add_permission()__

  And at each step of the way, you can change the params for any one of these insertions.
  """
  alias AppCount.Support.PropertyBuilder, as: Builder
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Properties.Feature
  alias AppCount.Properties.Unit
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Category
  alias AppCount.Repo
  alias AppCount.Maintenance.Utils.Assignments
  alias AppCount.Maintenance.Job
  alias AppCount.Admins.AdminRepo
  alias AppCount.Core.Clock
  alias AppCount.RentApply.Person
  alias AppCount.RentApply.RentApplication
  alias AppCount.Core.ClientSchema
  defstruct req: %{}, sequence_num: nil
  @top 1_000_000

  def new(_mode \\ :unused) do
    %Builder{sequence_num: Enum.random(1..@top)}
  end

  # Look into why cant use create function to add in client.
  def add_client(%Builder{} = builder, extra \\ []) do
    params =
      %{
        name: "client",
        status: "active",
        client_schema: "client"
      }
      |> Map.merge(Map.new(extra))

    {:ok, client} =
      %AppCount.Public.Client{}
      |> AppCount.Public.Client.changeset(params)
      |> AppCount.Repo.insert(prefix: "public")

    put_requirement(builder, :client, client)
  end

  def add_region(%Builder{req: %{}} = builder, _extra \\ []) do
    {unique_number, builder} = sequence(builder)

    resources = [
      "prospects",
      "admins",
      "properties",
      "units",
      "leads",
      "occupants",
      "rentals",
      "properties",
      "mail_addresses"
    ]

    attrs = %{
      name: "region-#{unique_number}",
      resources: resources
    }

    {:ok, region} =
      AppCount.Admins.Utils.Entities.create_entity(ClientSchema.new("dasmen", attrs))

    put_requirement(builder, :region, region)
  end

  def add_payment(builder, extra \\ [])

  def add_payment(%Builder{req: %{property: property, tenant: tenant}} = builder, extra) do
    start_of_month_on = Clock.beginning_of_month()

    payment = %AppCount.Ledgers.Payment{
      post_month: start_of_month_on,
      amount: Decimal.new(1000),
      property_id: property.id,
      tenant_id: tenant.id,
      source: "a good source",
      transaction_id: "939"
    }

    payment = create(builder, payment, extra)
    put_requirement(builder, :payment, payment)
  end

  def add_payment(%Builder{req: %{property: property}} = builder, extra) do
    start_of_month_on = Clock.beginning_of_month()

    payment = %AppCount.Ledgers.Payment{
      post_month: start_of_month_on,
      amount: Decimal.new(1000),
      property_id: property.id,
      source: "a good source",
      transaction_id: "939"
    }

    payment = create(builder, payment, extra)
    put_requirement(builder, :payment, payment)
  end

  def add_scoping(%Builder{req: %{property: property, region: region}} = builder, extra \\ []) do
    scoping = %AppCount.Properties.Scoping{property_id: property.id, region_id: region.id}

    scoping = create(builder, scoping, extra)
    put_requirement(builder, :scoping, scoping)
  end

  def add_permission(%Builder{req: %{region: region, admin: admin}} = builder, extra \\ []) do
    permission = %AppCount.Admins.Permission{admin_id: admin.id, region_id: region.id}

    permission = create(builder, permission, extra)
    put_requirement(builder, :permission, permission)
  end

  def add_admin_with_access(%Builder{} = builder, _extra \\ []) do
    builder
    |> add_region()
    |> add_scoping()
    |> add_admin()
    |> add_permission()
  end

  def add_super_admin(%Builder{} = builder) do
    add_admin(builder, roles: ["Super Admin"])
  end

  def add_regional_admin(%Builder{} = builder) do
    add_admin(builder, roles: ["Regional"])
  end

  def add_admin_alert(%Builder{req: %{admin: admin}} = builder, extra \\ []) do
    params =
      %{
        admin_id: admin.id,
        flag: 1,
        note: "This is a note",
        sender: "TestSuite"
      }
      |> Map.merge(Map.new(extra))

    alert = AppCount.Admins.create_alert(ClientSchema.new("dasmen", params))

    put_requirement(builder, :alert, alert)
  end

  # deprecated: use: add_admin/2
  def add_factory_admin(%Builder{req: %{property: _property}} = builder, _extra \\ []) do
    add_admin_with_access(builder, [])
  end

  def add_rent_application(
        %Builder{req: %{property: property}} = builder,
        extra \\ []
      ) do
    params = %RentApplication{property_id: property.id}

    rent_application = create(builder, params, extra)
    put_requirement(builder, :rent_application, rent_application)
  end

  def add_person(%Builder{req: %{rent_application: rent_application}} = builder, extra \\ []) do
    params = %Person{
      application_id: rent_application.id,
      full_name: "full_name",
      ssn: "123456789",
      email: "email@example.com",
      status: "Lease Holder",
      dob: Date.utc_today(),
      dl_number: "1",
      dl_state: "OH",
      home_phone: "1235551234"
    }

    person = create(builder, params, extra)
    put_requirement(builder, :person, person)
  end

  def add_admin(%Builder{} = builder, extra \\ []) do
    {unique_number, builder} = sequence(builder)

    attrs =
      %{
        name: "admin-#{unique_number}",
        email: "admin-#{unique_number}@example.com",
        username: "username-admin-#{unique_number}",
        password_hash: "hash",
        roles: ["Admin"],
        uuid: UUID.uuid4(),
        reset_pw: true
      }
      |> Map.merge(Map.new(extra))

    # This is perfered approach. Use Production code to create
    {:ok, admin} = AdminRepo.insert(attrs)
    admin = %{admin | roles: MapSet.new(admin.roles)}

    client = AppCount.Public.get_client_by_schema("dasmen")

    user_params =
      Map.merge(Map.from_struct(admin), %{
        type: "Admin",
        tenant_account_id: admin.id,
        password: "test_password",
        client_id: client.id
      })

    # Create features for that client.
    client_features = %{flag_name: "admin", client_id: client.id, enabled: true}

    client_features
    |> Enum.into(client_features)
    |> AppCount.Public.create_client_feature()

    features = %{client_features.flag_name => client_features.enabled}

    user =
      case AppCount.Public.Accounts.create_user(user_params) do
        {:ok, user} ->
          AppCount.Public.Accounts.get_user!(user.id)

        error ->
          error
      end

    # client = Map.put(user.client, :features, features)
    user = Map.put(user, :features, features)
    # admin = Map.put(admin, :user, client)
    admin = Map.put(admin, :user, user)
    put_requirement(builder, :admin, admin)
  end

  def add_parent_category(%Builder{} = builder, extra \\ []) do
    {unique_number, builder} = sequence(builder)

    parent_category = %Category{
      name: extra[:name] || "#{unique_number} Bedrooms"
    }

    parent_category = create(builder, parent_category, extra)
    put_requirement(builder, :parent_category, parent_category)
  end

  def add_category(%Builder{req: %{parent_category: parent_category}} = builder, extra \\ []) do
    {unique_number, builder} = sequence(builder)

    category =
      %Category{
        name: "#{unique_number} Bedrooms"
      }
      |> put_association(:parent, parent_category)

    category = create(builder, category, extra)
    put_requirement(builder, :category, category)
  end

  def add_vendor_category(%Builder{} = builder, extra \\ []) do
    {unique_number, builder} = sequence(builder)

    vendor_category = %AppCount.Vendors.Category{
      name: "Vendor-Category-#{unique_number}"
    }

    vendor_category = create(builder, vendor_category, extra)
    put_requirement(builder, :vendor_category, vendor_category)
  end

  def add_feature(%Builder{req: %{property: property}} = builder, extra \\ []) do
    {unique_number, builder} = sequence(builder)

    feature =
      %Feature{
        name: "#{unique_number} Bedrooms",
        price: 250,
        start_date: Clock.today()
      }
      |> put_association(:property, property)

    feature = create(builder, feature, extra)
    put_requirement(builder, :feature, feature)
  end

  def add_vendor(%Builder{} = builder, extra \\ []) do
    {vendor_num, builder} = sequence(builder)

    vendor = %AppCount.Vendors.Vendor{
      name: "Vendor #{vendor_num}",
      email: "email#{vendor_num}@example.com"
    }

    vendor = create(builder, vendor, extra)
    put_requirement(builder, :vendor, vendor)
  end

  def add_vendor_work_order(
        %Builder{
          req: %{property: property, vendor_category: vendor_category, unit: unit, vendor: vendor}
        } = builder,
        extra \\ []
      ) do
    vendor_work_order =
      %AppCount.Vendors.Order{
        has_pet: false,
        unit_id: unit.id,
        entry_allowed: false,
        priority: 1,
        ticket: "UNKNOWN",
        status: "Open",
        uuid: Ecto.UUID.generate(),
        vendor_id: vendor.id
      }
      |> put_association(:property, property)
      |> put_association(:category, vendor_category)

    vendor_work_order = create(builder, vendor_work_order, extra)
    put_requirement(builder, :vendor_work_order, vendor_work_order)
  end

  def add_work_order_on_unit(
        %Builder{req: %{property: property, category: category, unit: unit}} = builder,
        extra \\ []
      ) do
    work_order =
      %Order{
        has_pet: false,
        unit_id: unit.id,
        entry_allowed: false,
        priority: 1,
        ticket: "UNKNOWN",
        status: extra[:status] || "unassigned",
        uuid: Ecto.UUID.generate(),
        inserted_at: extra[:inserted_at]
      }
      |> put_association(:property, property)
      |> put_association(:category, category)

    work_order = create(builder, work_order, extra)
    put_requirement(builder, :work_order, work_order)
  end

  def add_work_order_on_unit_special_case_no_category(
        %Builder{req: %{property: property, unit: unit}} = builder,
        extra \\ []
      ) do
    work_order =
      %Order{
        has_pet: false,
        unit_id: unit.id,
        entry_allowed: false,
        priority: 1,
        ticket: "UNKNOWN",
        status: extra[:status] || "unassigned",
        uuid: Ecto.UUID.generate(),
        inserted_at: extra[:inserted_at]
      }
      |> put_association(:property, property)

    work_order = create(builder, work_order, extra)
    put_requirement(builder, :work_order, work_order)
  end

  def add_work_order_on_property(
        %Builder{req: %{property: property, category: category}} = builder,
        extra \\ []
      ) do
    work_order =
      %Order{
        has_pet: false,
        entry_allowed: false,
        priority: 1,
        ticket: "UNKNOWN",
        status: "unassigned",
        uuid: Ecto.UUID.generate()
      }
      |> put_association(:property, property)
      |> put_association(:category, category)

    work_order = create(builder, work_order, extra)
    put_requirement(builder, :work_order, work_order)
  end

  def add_lease_for(
        %Builder{req: %{unit: _unit, tenant: _tenant}} = builder,
        %AppCount.Core.DateRange{from: from, to: to}
      ) do
    add_lease(builder, start_date: from, end_date: to)
  end

  def add_lease(%Builder{req: %{unit: unit, tenant: tenant}} = builder, extra \\ []) do
    lease_attrs =
      %{
        start_date: Clock.today() |> Timex.shift(days: -1),
        end_date: Clock.today() |> Timex.shift(years: 1),
        actual_move_in: Clock.today() |> Timex.shift(days: -2),
        unit_id: unit.id,
        tenant_id: tenant.id,
        deposit_amount: 950,
        charges: [%{account_id: AppCount.Factory.insert(:account).id, amount: 950}]
      }
      |> Map.merge(Map.new(extra))

    {:ok, %{lease: lease}} = AppCount.Leases.create_lease(ClientSchema.new("dasmen", lease_attrs))

    put_requirement(builder, :lease, lease)
  end

  def add_customer_ledger(%Builder{req: %{property: property}} = builder, extra \\ []) do
    attrs =
      %{
        property_id: property.id,
        name: "Generic Name",
        type: "tenant"
      }
      |> Map.merge(Map.new(extra))

    {:ok, customer_ledger} = AppCount.Ledgers.CustomerLedgerRepo.insert(attrs)

    put_requirement(builder, :customer_ledger, customer_ledger)
  end

  def add_ledger_charge(%Builder{req: %{customer_ledger: ledger}} = builder, extra \\ []) do
    attrs =
      %{
        customer_ledger_id: ledger.id,
        amount: 950,
        status: "charge",
        bill_date: AppCount.current_date(),
        post_month: Timex.beginning_of_month(AppCount.current_date()),
        charge_code_id: AppCount.Factory.insert(:charge_code).id
      }
      |> Map.merge(Map.new(extra))

    {:ok, charge} = AppCount.Ledgers.ChargeRepo.insert(attrs)

    put_requirement(builder, :charge, charge)
  end

  def add_tenancy(
        %Builder{req: %{unit: unit, tenant: tenant, customer_ledger: ledger}} = builder,
        extra \\ []
      ) do
    tenancy_attrs =
      %{
        start_date: Clock.today() |> Timex.shift(days: -1),
        actual_move_in: Clock.today() |> Timex.shift(days: -2),
        unit_id: unit.id,
        tenant_id: tenant.id,
        customer_ledger_id: ledger.id
      }
      |> Map.merge(Map.new(extra))

    {:ok, tenancy} = AppCount.Tenants.TenancyRepo.insert(tenancy_attrs)

    put_requirement(builder, :tenancy, tenancy)
  end

  def add_renewal(%Builder{req: %{lease: lease, tenant: tenant}} = builder, extra \\ []) do
    lease_attrs =
      %{
        start_date: lease.end_date |> Timex.shift(days: 1),
        end_date: lease.end_date |> Timex.shift(years: 1),
        unit_id: lease.unit_id,
        tenant_id: tenant.id
      }
      |> Map.merge(Map.new(extra))

    {:ok, %{lease: new_lease}} =
      AppCount.Leases.create_lease(ClientSchema.new("dasmen", lease_attrs))

    {:ok, %{lease: updated_lease}} =
      AppCount.Leases.update_lease(lease.id, %{renewal_id: new_lease.id})

    builder
    |> put_requirement(:lease, updated_lease)
    |> put_requirement(:renewal, new_lease)
  end

  def add_tenant(builder, extra \\ [])

  def add_tenant(%Builder{req: %{rent_application: rent_application}} = builder, extra) do
    {tenant_number, builder} = sequence(builder)

    tenant_attrs = %AppCount.Tenants.Tenant{
      application_id: rent_application.id,
      first_name: "First#{tenant_number}",
      last_name: "Last#{tenant_number}",
      email: "someguy#{tenant_number}@yahoo.com",
      uuid: UUID.uuid4()
    }

    tenant = create(builder, tenant_attrs, extra)

    builder
    |> put_requirement(:tenant, tenant)
  end

  def add_tenant(%Builder{} = builder, extra) do
    {tenant_number, builder} = sequence(builder)

    tenant_attrs = %AppCount.Tenants.Tenant{
      first_name: "First#{tenant_number}",
      last_name: "Last#{tenant_number}",
      email: "someguy#{tenant_number}@yahoo.com",
      uuid: UUID.uuid4()
    }

    tenant = create(builder, tenant_attrs, extra)

    builder
    |> put_requirement(:tenant, tenant)
  end

  def add_tenant_account(%Builder{req: %{tenant: tenant}} = builder, _extra \\ []) do
    {:ok, tenant_account} = AppCount.Accounts.create_tenant_account(tenant.id)

    builder
    |> put_requirement(:tenant_account, tenant_account)
  end

  def add_account_login(%Builder{req: %{tenant_account: tenant_account}} = builder, _extra \\ []) do
    {:ok, login} =
      AppCount.Accounts.Utils.Logins.create_login(%{account_id: tenant_account.id, type: "web"})

    tenant_account = %{tenant_account | logins: [login]}

    builder
    |> put_requirement(:tenant_account, tenant_account)
  end

  def add_account_lock(%Builder{req: %{tenant_account: account}} = builder, extra \\ []) do
    params =
      %{
        account_id: account.id,
        reason: "Just Because I Said So",
        enabled: true
      }
      |> Map.merge(Map.new(extra))

    {:ok, account_lock} = AppCount.Accounts.create_lock(params)

    builder
    |> put_requirement(:account_lock, account_lock)
  end

  def add_unit_category(builder) do
    builder
    |> add_parent_category()
    |> add_category()
  end

  def add_unit(builder, extra \\ [])

  def add_unit(%Builder{req: %{property: property, feature: feature}} = builder, extra) do
    {unit_number, builder} = sequence(builder)

    unit =
      %Unit{
        number: "#{unit_number}",
        features: [feature],
        uuid: UUID.uuid4()
      }
      |> put_association(:property, property)

    unit = create(builder, unit, extra)

    put_requirement(builder, :unit, unit)
  end

  def add_unit(%Builder{} = builder, extra) do
    builder
    |> add_feature()
    |> add_unit(extra)
  end

  def add_card(%Builder{req: %{unit: unit}} = builder, extra \\ []) do
    card = %AppCount.Maintenance.Card{
      move_out_date: Timex.now() |> Timex.to_date(),
      unit_id: unit.id,
      admin: "Some Admin"
    }

    card = create(builder, card, extra)
    put_requirement(builder, :card, card)
  end

  def add_card_item(%Builder{req: %{card: card}} = builder, extra \\ []) do
    card_item = %AppCount.Maintenance.CardItem{
      card_id: card.id,
      name: "Name"
    }

    card_item = create(builder, card_item, extra)
    put_requirement(builder, :card_item, card_item)
  end

  def add_property(%Builder{} = builder, extra \\ []) do
    {code_num, builder} = sequence(builder)
    extra_params = Map.new(extra)

    params =
      %{
        name: "Test Property-#{code_num}",
        code: "prop-#{code_num}",
        address: %{
          zip: "28205",
          street: "3317 Magnolia Hill Dr",
          state: "NC",
          city: "Charlotte"
        },
        terms: "These are my terms, take 'em or leave 'em",
        social: %{}
      }
      |> Map.merge(extra_params)

    {:ok, property} =
      AppCount.Properties.PropertyRepo.create_property(ClientSchema.new("dasmen", params))

    put_requirement(builder, :property, property)
  end

  def add_property_setting(%Builder{req: %{property: property}} = builder, extra \\ []) do
    attrs = Map.new(extra)

    property = PropertyRepo.update_property_settings(property, ClientSchema.new("dasmen", attrs))

    put_requirement(builder, :property, property)
  end

  def add_property_setting_bank_account(
        %Builder{req: %{property: property}} = builder,
        extra \\ []
      ) do
    settings_attrs = Map.new(extra)

    {:ok, bank_account} =
      AppCount.Accounting.create_bank_account(%{
        "name" => "Some Body",
        "bank_name" => "Wells Fakeout",
        "routing_number" => "956325",
        "account_number" => "92567252452",
        "account_id" => AppCount.Factory.insert(:account).id,
        "property_ids" => [property.id]
      })

    settings_attrs = Map.put(settings_attrs, :default_bank_account_id, bank_account.id)

    property =
      PropertyRepo.update_property_settings(property, ClientSchema.new("dasmen", settings_attrs))

    put_requirement(builder, :property, property)
  end

  def add_processor(%Builder{req: %{property: property}} = builder, extra \\ []) do
    types = %{
      "cc" => "Authorize",
      "screening" => "TenantSafe",
      "management" => "Yardi",
      "lease" => "BlueMoon",
      "ba" => "Payscape"
    }

    type = Keyword.get(extra, :type, "cc")
    name = Map.get(types, type, "Authorize")

    processor_attrs =
      %{
        keys: ["welcome", "welcome", "Employment Search"],
        type: type,
        name: name,
        login: "Username",
        password: "password"
      }
      |> put_association(:property, property)

    # We need to create from attributes, rather than the schema directly,
    # because of how encrypted fields work.
    processor = create_from_attrs(builder, AppCount.Properties.Processor, processor_attrs, extra)
    put_requirement(builder, :processor, processor)
  end

  def add_tech(%Builder{req: %{property: property}} = builder, extra \\ []) do
    tech_attrs =
      %{
        name: "Harry",
        email: "techie@example.com",
        phone_number: "1235551234",
        active: true
      }
      |> Map.merge(Map.new(extra))

    # useas the Repo to create data because it enforces the production creation semantics
    {:ok, tech} = AppCount.Maintenance.TechRepo.insert(tech_attrs)

    %Job{tech_id: tech.id, property_id: property.id}
    |> Job.changeset(%{})
    |> AppCount.Repo.insert()

    put_requirement(builder, :tech, tech)
  end

  def create_property_work_order(%Builder{} = builder, task_begin, admin, prefix, options \\ []) do
    builder
    |> add_work_order_on_property(inserted_at: task_begin)
    |> exec_assign_order(admin)
    |> exec_accept_assignment()
    |> exec_complete_assignment(prefix, options)
  end

  def create_open_unit_work_order(%Builder{} = builder, %NaiveDateTime{} = task_begin, admin) do
    builder
    |> add_work_order_on_unit(inserted_at: task_begin)
    |> exec_assign_order(admin)
    |> exec_accept_assignment()
  end

  def create_unit_work_order(
        %Builder{} = builder,
        %NaiveDateTime{} = task_begin,
        admin,
        prefix,
        options \\ []
      ) do
    builder
    |> create_open_unit_work_order(task_begin, admin)
    |> exec_complete_assignment(prefix, options)
  end

  def add_work_order_assignment(
        %Builder{req: %{tech: tech, work_order: work_order, admin: admin}} = builder
      ) do
    assignment =
      ClientSchema.new(tech.__meta__.prefix, work_order.id)
      |> Assignments.assign_order(tech.id, admin.id)

    builder
    |> put_requirement(:assignment, assignment)
  end

  #
  # "exec_" functions in this section use the production code logic to transform the data in the DB
  #
  def exec_assign_order(%Builder{req: %{tech: tech, work_order: work_order}} = builder, admin) do
    assignment =
      ClientSchema.new(tech.__meta__.prefix, work_order.id)
      |> Assignments.assign_order(tech.id, admin.id)

    builder
    |> put_requirement(:assignment, assignment)
  end

  def exec_accept_assignment(%Builder{req: %{assignment: assignment}} = builder) do
    assignment =
      ClientSchema.new(assignment.__meta__.prefix, assignment.id)
      |> Assignments.accept_assignment()

    builder |> put_requirement(:assignment, assignment)
  end

  def exec_reject_assignment(
        %Builder{req: %{assignment: assignment}} = builder,
        reason \\ "rejected"
      ) do
    assignment =
      ClientSchema.new(assignment.__meta__.prefix, assignment.id)
      |> Assignments.reject_assignment(reason)

    builder |> put_requirement(:assignment, assignment)
  end

  def exec_complete_assignment(
        %Builder{req: %{assignment: assignment}} = builder,
        client_schema,
        options \\ []
      ) do
    assignment =
      Assignments.complete_assignment(
        ClientSchema.new(client_schema, assignment.id),
        Map.new(options)
      )

    builder
    |> put_requirement(:assignment, assignment)
  end

  def exec_callback_assignment(%Builder{req: %{assignment: assignment}} = builder) do
    assignment = Assignments.callback_assignment(assignment)

    builder
    |> put_requirement(:assignment, assignment)
  end

  def exec_rate_assignment(%Builder{req: %{assignment: assignment}} = builder, rating) do
    {:ok, assignment} = Assignments.rate_assignment(assignment.id, rating)

    builder
    |> put_requirement(:assignment, assignment)
  end

  # --------------------------------------------------------
  # Private
  # --------------------------------------------------------
  def get(%Builder{} = builder, names) when is_list(names) do
    requirements =
      names
      |> Enum.map(fn name -> priv_get(builder, name) end)

    [builder] ++ requirements
  end

  defp priv_get(%Builder{req: req}, name) do
    Map.get(req, name, "#{name} Not Found")
  end

  def get_requirement(%Builder{req: req}, :property) do
    property = Map.fetch!(req, :property)
    AppCount.Properties.PropertyRepo.get_aggregate(property.id)
  end

  def get_requirement(%Builder{req: req}, name) do
    Map.get(req, name, "#{name} Not Found")
  end

  def put_requirement(%Builder{req: req} = builder, name, value) do
    req = Map.put(req, name, value)
    %{builder | req: req}
  end

  defp sequence(%Builder{sequence_num: sequence_num} = builder) do
    builder = %{builder | sequence_num: sequence_num + 1}
    {sequence_num, builder}
  end

  defp create(%Builder{}, %module_name{} = schema, extra) do
    schema
    |> merge(extra)
    |> module_name.changeset(%{})
    |> Repo.insert!()
  end

  # When we're working structs that have encrypted fields, we need to create
  # them slightly differently. In this case, we pass in an atom representing the
  # module name, e.g. AppCount.Properties.Processor, and a map with the various
  # attributes.
  defp create_from_attrs(%Builder{}, module_name, attrs, extra) do
    params = merge(attrs, extra)

    {:ok, %{id: id}} =
      struct(module_name)
      |> module_name.changeset(params)
      |> Repo.insert()

    # Re-fetch to get un-encrypted attrs
    Repo.get(module_name, id)
  end

  defp put_association(target, association_name, association_struct) do
    association_name = "#{association_name}_id" |> String.to_atom()

    target
    |> Map.put(association_name, association_struct.id)
  end

  defp merge(struct, extra_as_keyword_list) do
    Map.merge(struct, Map.new(extra_as_keyword_list))
  end
end
