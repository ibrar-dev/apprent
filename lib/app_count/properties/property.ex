defmodule AppCount.Properties.Property do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment
  alias AppCount.TimeZones

  # WARNING this will still fail in production.any()
  # previous error was https://app.honeybadger.io/projects/79008/faults/73500305#notice-trace
  #
  # we add only one field so we can find the place that is calling this.
  @derive {Jason.Encoder, only: [:name]}

  schema "properties__properties" do
    field(:name, :string)
    field(:code, :string)
    field(:external_id, :string)
    field(:address, :map)
    attachment(:banner)
    attachment(:icon)
    attachment(:logo)
    field(:group_email, :string)
    field(:lat, :decimal)
    field(:lng, :decimal)
    field(:phone, :string, default: "")
    field(:primary_color, :string, default: "#6ECD0B")
    field(:social, :map)
    field(:terms, :string, default: "")
    field(:time_zone, :string, default: "US/Eastern")
    field(:website, :string, default: "")
    has_many(:floor_plans, Module.concat(["AppCount.Properties.FloorPlan"]))
    has_many(:scopings, Module.concat(["AppCount.Properties.Scoping"]))
    has_many(:showings, Module.concat(["AppCount.Prospects.Showing"]))
    has_many(:units, Module.concat(["AppCount.Properties.Unit"]))
    has_many(:insight_reports, AppCount.Maintenance.InsightReport)
    has_many(:phone_numbers, AppCount.Messaging.PhoneNumber)
    belongs_to :public_property, AppCount.Public.Property

    many_to_many(
      :regions,
      Module.concat(["AppCount.Admins.Region"]),
      join_through: Module.concat(["AppCount.Properties.Scoping"])
    )

    many_to_many(
      :bank_accounts,
      Module.concat(["AppCount.Accounting.BankAccount"]),
      join_through: Module.concat(["AppCount.Accounting.Entity"])
    )

    many_to_many(
      :devices,
      Module.concat(["AppCount.Admins.Device"]),
      join_through: Module.concat(["AppCount.Admins.DeviceAuth"])
    )

    has_many(:registers, Module.concat(["AppCount.Accounting.Register"]))

    many_to_many(
      :accounts,
      Module.concat(["AppCount.Accounting.Account"]),
      join_through: Module.concat(["AppCount.Accounting.Register"])
    )

    belongs_to(:region, Module.concat(["AppCount.Properties.Region"]))

    has_one(:setting, Module.concat(["AppCount.Properties.Setting"]))
    belongs_to(:stock, Module.concat(["AppCount.Materials.Stock"]))
    has_many(:processors, Module.concat(["AppCount.Properties.Processor"]))
    has_many(:phone_lines, Module.concat(["AppCount.Properties.PhoneLine"]))

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :address,
      :code,
      :group_email,
      :lat,
      :lng,
      :name,
      :phone,
      :primary_color,
      :group_email,
      :region_id,
      :external_id,
      :region_id,
      :social,
      :stock_id,
      :terms,
      :time_zone,
      :public_property_id,
      :website
    ])
    |> cast_attachment(:banner, public: true)
    |> cast_attachment(:icon, public: true)
    |> cast_attachment(:logo, public: true)
    |> validate_required([:name, :code, :address, :time_zone])
    |> validate_inclusion(:time_zone, TimeZones.timezones())
    |> unique_constraint(:code)
    |> unique_constraint(:external_id)
    |> unique_constraint(:api_key)
  end

  @geocode_url "https://maps.googleapis.com/maps/api/geocode/json?"

  def geocode(%{address: address} = prop, key) do
    formatted_address =
      "#{address["street"]}, #{address["city"]} #{address["state"]} #{address["zip"]}}"

    params =
      %{address: formatted_address, key: key}
      |> URI.encode_query()

    (@geocode_url <> params)
    |> HTTPoison.get()
    |> case do
      {:ok, %{body: body}} ->
        loc =
          body
          |> Poison.decode!()
          |> Map.get("results")
          |> List.first()
          |> Map.get("geometry")
          |> Map.get("location")

        prop
        |> changeset(loc)
        |> AppCount.Repo.update()

      {:error, error} ->
        error
    end
  end
end
