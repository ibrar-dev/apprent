defmodule AppCount.Properties.Utils.Properties do
  alias AppCount.Admins
  alias AppCount.Repo
  alias AppCount.Properties.Property
  alias AppCount.Properties.Setting
  alias AppCount.Properties.FloorPlan
  alias AppCount.Properties.Processors
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.ClientSchema

  import Ecto.Query
  import AppCount.EctoExtensions
  require Logger

  def public_property_data(%AppCount.Core.ClientSchema{name: client_schema, attrs: attrs}) do
    code = attrs.code

    field =
      cond do
        is_integer(code) -> :id
        Integer.parse(code) != :error -> :id
        true -> :code
      end

    fp_query =
      from(
        fp in FloorPlan,
        select: %{
          id: fp.id,
          name: fp.name,
          property_id: fp.property_id
        }
      )

    from(
      p in Property,
      left_join: l in assoc(p, :logo_url),
      left_join: i in assoc(p, :icon_url),
      left_join: b in assoc(p, :banner_url),
      left_join: fp in subquery(fp_query),
      on: fp.property_id == p.id,
      join: s in assoc(p, :setting),
      select: %{
        agreement_text: s.agreement_text,
        id: p.id,
        name: p.name,
        code: p.code,
        address: p.address,
        phone: p.phone,
        website: p.website,
        lat: p.lat,
        lng: p.lng,
        logo: l.url,
        icon: i.url,
        banner: b.url,
        primary_color: p.primary_color,
        floor_plans: jsonize(fp, [:id, :name]),
        instant_screen: s.instant_screen,
        accepting_applications: s.applications,
        accepting_tours: s.tours,
        application_fee: s.application_fee,
        admin_fee: s.admin_fee
      },
      where: field(p, ^field) == ^code,
      group_by: [p.id, l.url, i.url, b.url, s.id]
    )
    |> Repo.one(prefix: client_schema)
    |> merge_public_cc_processor_details()
  end

  def list_properties(%ClientSchema{name: client_schema, attrs: admin}, :min) do
    from(
      p in Property,
      left_join: i in assoc(p, :icon_url),
      left_join: s in assoc(p, :setting),
      where: p.id in ^admin.property_ids,
      order_by: [
        asc: p.name
      ],
      select: map(p, [:id, :name, :lat, :lng, :stock_id, :region, :external_id]),
      select_merge: %{
        icon: i.url,
        sync_payments: s.sync_payments,
        sync_ledgers: s.sync_ledgers,
        sync_residents: s.sync_residents
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_properties(%ClientSchema{name: client_schema, attrs: admin}) do
    from(
      p in Property,
      left_join: s in assoc(p, :setting),
      left_join: r in assoc(p, :registers),
      left_join: ca in assoc(r, :account),
      left_join: l in assoc(p, :logo_url),
      left_join: i in assoc(p, :icon_url),
      left_join: b in assoc(p, :banner_url),
      where: p.id in ^admin.property_ids,
      select: map(p, ^schema_fields(Property)),
      select_merge: %{
        logo: l.url,
        icon: i.url,
        banner: b.url,
        settings: map(s, ^schema_fields(Setting)),
        cash_accounts: jsonize(r, [:id, :is_default, {:name, ca.name}])
      },
      group_by: [p.id, s.id, l.url, i.url, b.url],
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_active_properties(%ClientSchema{name: client_schema, attrs: admin}) do
    list_properties(ClientSchema.new(client_schema, admin))
    |> Enum.filter(fn prop -> prop.settings.active end)
  end

  def list_public_properties(%ClientSchema{name: client_schema, attrs: _admin}) do
    from(
      p in Property,
      left_join: l in assoc(p, :logo_url),
      left_join: i in assoc(p, :icon_url),
      left_join: b in assoc(p, :banner_url),
      join: s in assoc(p, :setting),
      where: s.active == true,
      select: %{
        id: p.id,
        name: p.name,
        code: p.code,
        address: p.address,
        phone: p.phone,
        website: p.website,
        lat: p.lat,
        lng: p.lng,
        logo: l.url,
        icon: i.url,
        banner: b.url,
        primary_color: p.primary_color
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def property_info(property_id) do
    admin_query =
      from(
        a in AppCount.Admins.Admin,
        join: p in assoc(a, :profile),
        left_join: image in assoc(p, :image_url),
        on: p.admin_id == a.id,
        join: per in assoc(a, :permissions),
        join: e in assoc(per, :region),
        join: sco in assoc(e, :scopings),
        join: prop in assoc(sco, :property),
        where: prop.id == ^property_id and p.active,
        select: %{
          id: a.id,
          name: a.name,
          image: image.url,
          title: p.title,
          bio: p.bio,
          admin_id: p.admin_id,
          property_id: prop.id
        }
      )

    from(
      p in Property,
      left_join: a in subquery(admin_query),
      left_join: l in assoc(p, :logo_url),
      left_join: i in assoc(p, :icon_url),
      left_join: b in assoc(p, :banner_url),
      left_join: setting in assoc(p, :setting),
      on: a.property_id == p.id,
      select: %{
        id: p.id,
        name: p.name,
        logo: max(l.url),
        icon: max(i.url),
        phone: p.phone,
        lat: p.lat,
        lng: p.lng,
        banner: max(b.url),
        address: p.address,
        website: p.website,
        primary_color: p.primary_color,
        team: jsonize(a, [:id, :name, :image, :bio, :title]),
        social: p.social,
        agreement_text: max(setting.agreement_text),
        email: p.group_email
      },
      where: p.id == ^property_id,
      group_by: [p.id]
    )
    |> Repo.one()
  end

  def get_property(admin, %AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    from(
      p in Property,
      left_join: s in assoc(p, :setting),
      left_join: r in assoc(p, :registers),
      left_join: ca in assoc(r, :account),
      left_join: l in assoc(p, :logo_url),
      left_join: i in assoc(p, :icon_url),
      left_join: b in assoc(p, :banner_url),
      left_join: pn in assoc(p, :phone_numbers),
      where: p.id in ^admin.property_ids and p.id == ^id,
      select: map(p, ^schema_fields(Property)),
      select_merge: %{
        logo: l.url,
        icon: i.url,
        banner: b.url,
        settings: map(s, ^schema_fields(Setting)),
        accounts: jsonize(r, [:id, :type, :is_default, {:name, ca.name}]),
        phone_numbers: jsonize(pn, [:id, :number, :context])
      },
      group_by: [p.id, s.id, l.url, i.url, b.url],
      order_by: [
        asc: :name
      ]
    )
    |> Repo.one(prefix: client_schema)
  end

  def get_property([{param, value}], schema) do
    from(
      p in Property,
      left_join: s in assoc(p, :setting),
      left_join: i in assoc(p, :icon_url),
      left_join: l in assoc(p, :logo_url),
      where: field(p, ^param) == ^value,
      select: p,
      preload: [
        setting: s
      ],
      select_merge: %{
        icon: i.url,
        logo: l.url
      }
    )
    |> Repo.one(prefix: schema)
  end

  def get_property(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    from(
      p in Property,
      left_join: s in assoc(p, :setting),
      left_join: i in assoc(p, :icon_url),
      left_join: l in assoc(p, :logo_url),
      where: p.id == ^id,
      select: p,
      preload: [
        setting: s
      ],
      select_merge: %{
        icon: i.url,
        logo: l.url
      }
    )
    |> Repo.one(prefix: client_schema)
  end

  # TODO:SCHEMA not required when schema's are fixed for all
  # def get_property(id) do
  #   from(
  #     p in Property,
  #     left_join: s in assoc(p, :setting),
  #     left_join: i in assoc(p, :icon_url),
  #     left_join: l in assoc(p, :logo_url),
  #     where: p.id == ^id,
  #     select: p,
  #     preload: [
  #       setting: s
  #     ],
  #     select_merge: %{
  #       icon: i.url,
  #       logo: l.url
  #     }
  #   )
  #   |> Repo.one()
  # end

  def get_property_with_payment_keys(arg, schema) do
    arg
    |> get_property(schema)
    |> merge_public_cc_processor_details
  end

  def merge_public_cc_processor_details(%Property{id: id} = property) do
    Map.merge(property, %{public_cc_processor: Processors.public_details(id, :cc)})
  end

  def merge_public_cc_processor_details(%{id: id} = data) do
    Map.merge(data, %{public_cc_processor: Processors.public_details(id, :cc)})
  end

  def merge_public_cc_processor_details(nil) do
    nil
  end

  def create_property(
        %ClientSchema{name: client_schema, attrs: params},
        repo \\ PropertyRepo
      ) do
    repo.create_property(%ClientSchema{name: client_schema, attrs: params})
  end

  def update_property(
        %Property{} = property,
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %{"settings" => settings} = params
        }
      ) do
    _property =
      PropertyRepo.update_property_settings(
        property,
        ClientSchema.new(
          client_schema,
          Map.merge(settings, %{"bluemoon_credentials_confirmed" => nil})
        )
      )

    update_property(property, ClientSchema.new(client_schema, Map.delete(params, "settings")))
  end

  def update_property(%Property{} = property, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Property.changeset(property, params)
    # TEMP--can remove prefix later
    |> Repo.update(prefix: client_schema)
    |> case do
      {:ok, property} ->
        {:ok, _, property} = AppCount.Public.Utils.Properties.sync_public(property)
        {:ok, property}

      e ->
        e
    end
  end

  def update_property(id, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    ClientSchema.new(client_schema, id)
    |> get_property()
    |> update_property(ClientSchema.new(client_schema, params))
  end

  def geocode_all(admin) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    Enum.each(
      property_ids,
      fn property_id ->
        Repo.get(Property, property_id)
        |> Property.geocode("AIzaSyDTRoTfKt-IQBons2KjJAvLSDEGTDcqET4")
      end
    )
  end

  def delete_property(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    get_property(ClientSchema.new(client_schema, id))
    |> Repo.delete(prefix: client_schema)
  end
end
