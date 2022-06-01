defmodule AppCount.Properties.Utils.Features do
  alias AppCount.Repo
  alias AppCount.Properties.Feature
  alias AppCount.Properties.UnitFeature
  alias AppCount.Properties.FloorPlanFeature
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def list_features(%ClientSchema{name: client_schema, attrs: admin}) do
    fields = Feature.__schema__(:fields)

    from(
      f in Feature,
      join: p in assoc(f, :property),
      left_join: u in assoc(f, :units),
      select: map(f, ^fields),
      select_merge: %{
        units: jsonize(u, [:id, :number])
      },
      where: f.property_id in ^admin.property_ids,
      where: is_nil(f.stop_date),
      order_by: [
        asc: p.name
      ],
      group_by: [f.id, p.name]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_feature(%ClientSchema{name: client_schema, attrs: params}) do
    %Feature{}
    |> Feature.changeset(Map.put(params, "start_date", AppCount.current_date()))
    |> Repo.insert(prefix: client_schema)
  end

  def update_feature(id, %ClientSchema{
        name: client_schema,
        attrs: %{"unit_ids" => unit_ids} = params
      }) do
    from(f in UnitFeature, where: f.feature_id == ^id and f.unit_id not in ^unit_ids)
    |> Repo.delete_all(prefix: client_schema)

    unit_ids
    |> Enum.each(fn unit_id ->
      %UnitFeature{}
      |> UnitFeature.changeset(%{unit_id: unit_id, feature_id: id})
      |> Repo.insert(prefix: client_schema)
    end)

    update_feature(id, ClientSchema.new(client_schema, Map.delete(params, "unit_ids")))
  end

  def update_feature(id, %ClientSchema{name: client_schema, attrs: params}) do
    cs =
      Repo.get(Feature, id, prefix: client_schema)
      |> Feature.changeset(params)

    process_update(ClientSchema.new(client_schema, cs))
  end

  def delete_feature(%ClientSchema{name: client_schema, attrs: id}) do
    current_date = AppCount.current_date()
    feature = Repo.get(Feature, id, prefix: client_schema)

    if feature.start_date == current_date do
      Repo.delete(feature, prefix: client_schema)
    else
      feature
      |> Feature.changeset(%{stop_date: current_date})
      |> Repo.update(prefix: client_schema)
    end
  end

  defp process_update(%ClientSchema{
         name: client_schema,
         attrs: %{changes: %{price: new_price} = changes, data: original} = cs
       }) do
    current_date = AppCount.current_date()

    if original.start_date == current_date do
      Repo.update(cs, prefix: client_schema)
    else
      new_params =
        changes
        |> Map.delete(:price)
        |> Map.put(:stop_date, current_date)

      original
      |> Feature.changeset(new_params)
      |> Repo.update(prefix: client_schema)

      params =
        original
        |> Map.from_struct()
        |> Map.drop([:id, :created_at, :updated_at, :start_date])
        |> Map.merge(%{price: new_price, start_date: AppCount.current_date()})

      %Feature{}
      |> Feature.changeset(params)
      |> Repo.insert(prefix: client_schema)
      |> case do
        {:ok, f} ->
          transfer_feature_assocs(ClientSchema.new(client_schema, f), original)
          {:ok, f}

        e ->
          e
      end
    end
  end

  defp process_update(%ClientSchema{name: client_schema, attrs: cs}),
    do: Repo.update(cs, prefix: client_schema)

  defp transfer_feature_assocs(
         %ClientSchema{name: client_schema, attrs: new_version},
         old_version
       ) do
    from(f in FloorPlanFeature, where: f.feature_id == ^old_version.id, select: f.floor_plan_id)
    |> Repo.all(prefix: client_schema)
    |> Enum.each(fn floor_plan_id ->
      %FloorPlanFeature{}
      |> FloorPlanFeature.changeset(%{floor_plan_id: floor_plan_id, feature_id: new_version.id})
      |> Repo.insert(prefix: client_schema)
    end)

    from(f in UnitFeature, where: f.feature_id == ^old_version.id, select: f.unit_id)
    |> Repo.all(prefix: client_schema)
    |> Enum.each(fn unit_id ->
      %UnitFeature{}
      |> UnitFeature.changeset(%{unit_id: unit_id, feature_id: new_version.id})
      |> Repo.insert(prefix: client_schema)
    end)
  end
end
