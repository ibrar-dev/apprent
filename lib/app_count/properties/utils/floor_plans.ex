defmodule AppCount.Properties.Utils.FloorPlans do
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Properties.FloorPlan
  alias AppCount.Properties.FloorPlanFeature
  alias AppCount.Properties.Unit
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def list_floor_plans(%ClientSchema{name: client_schema, attrs: admin}) do
    units_sq =
      from(u in Unit,
        select: %{
          units: jsonize(u, [:id, :number]),
          floor_plan_id: u.floor_plan_id
        },
        group_by: u.floor_plan_id
      )

    from(
      f in FloorPlan,
      left_join: fea in assoc(f, :features),
      left_join: charges in assoc(f, :default_charges),
      left_join: u in subquery(units_sq),
      on: u.floor_plan_id == f.id,
      where: f.property_id in ^Admins.property_ids_for(ClientSchema.new(client_schema, admin)),
      where: is_nil(fea.stop_date),
      select: map(f, [:id, :name, :property_id]),
      select_merge: %{
        feature_ids: array(fea.id),
        price: sum(fea.price),
        units: u.units,
        charges: jsonize(charges, [:id, :price, :default_charge, :charge_code_id])
      },
      group_by: [f.id, u.units]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_floor_plan(%ClientSchema{name: client_schema, attrs: params}) do
    %FloorPlan{}
    |> FloorPlan.changeset(params)
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, fp} ->
        Enum.each(
          params["feature_ids"],
          &insert_floor_plan_feature(fp, ClientSchema.new(client_schema, &1))
        )

        {:ok, fp}

      e ->
        e
    end
  end

  def update_floor_plan(
        id,
        %ClientSchema{
          name: client_schema,
          attrs: %{"feature_ids" => feature_ids} = params
        }
      ) do
    from(
      f in FloorPlanFeature,
      where: f.floor_plan_id == ^id and f.feature_id not in ^feature_ids
    )
    |> Repo.delete_all(prefix: client_schema)

    Enum.each(
      feature_ids,
      &insert_floor_plan_feature(
        %{id: id},
        ClientSchema.new(client_schema, &1)
      )
    )

    update_floor_plan(id, ClientSchema.new(client_schema, Map.delete(params, "feature_ids")))
  end

  def update_floor_plan(
        id,
        %ClientSchema{
          name: client_schema,
          attrs: %{"unit_ids" => unit_ids} = params
        }
      ) do
    from(
      u in Unit,
      where: u.floor_plan_id == ^id and u.id not in ^unit_ids
    )
    |> Repo.update_all(
      prefix: client_schema,
      set: [
        floor_plan_id: nil
      ]
    )

    from(
      u in Unit,
      where: u.id in ^unit_ids
    )
    |> Repo.update_all(
      prefix: client_schema,
      set: [
        floor_plan_id: id
      ]
    )

    update_floor_plan(
      id,
      ClientSchema.new(client_schema, Map.delete(params, "unit_ids"))
    )
  end

  def update_floor_plan(id, %ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Repo.get(FloorPlan, id, prefix: client_schema)
    |> FloorPlan.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_floor_plan(%ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    Repo.get(FloorPlan, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  def floor_plan_market_rent(%ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    from(
      plan in FloorPlan,
      left_join: fp in assoc(plan, :features),
      where: is_nil(fp.stop_date),
      where: plan.id == ^id,
      select: coalesce(fp.price, 0),
      group_by: [plan.id, fp.price]
    )
    |> Repo.one(prefix: client_schema)
  end

  defp insert_floor_plan_feature(fp, %ClientSchema{
         name: client_schema,
         attrs: feature_id
       }) do
    %FloorPlanFeature{}
    |> FloorPlanFeature.changeset(%{floor_plan_id: fp.id, feature_id: feature_id})
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id]},
      conflict_target: [:feature_id, :floor_plan_id],
      prefix: client_schema
    )
  end
end
