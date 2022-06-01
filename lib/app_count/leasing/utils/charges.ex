defmodule AppCount.Leasing.Utils.Charges do
  @moduledoc """
    Used for batch updating of lease charges
  """
  import Ecto.Query
  alias Ecto.Multi
  alias AppCount.Repo
  alias AppCount.Leasing.Charge
  alias AppCount.Core.ClientSchema

  def update_charges(%ClientSchema{name: client_schema, attrs: admin}, lease_id, attrs) do
    Enum.map(attrs, &Morphix.atomorphiform!/1)
    |> validate_params
    |> case do
      {:error, _} = e ->
        e

      validated_attrs ->
        charge_attrs =
          validated_attrs
          |> Enum.map(
            &put_additional_charge_fields(
              %ClientSchema{name: client_schema, attrs: admin},
              lease_id,
              &1
            )
          )

        ClientSchema.new(client_schema, charge_attrs)
        |> do_update_charges()
    end
  end

  def delete_charge(%ClientSchema{name: client_schema, attrs: id}) do
    Repo.get(Charge, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  defp put_additional_charge_fields(%ClientSchema{} = schema, lease_id, charge_attrs) do
    charge_attrs
    |> Map.put(:lease_id, lease_id)
    |> maybe_put_edits(schema)
  end

  defp maybe_put_edits(%{id: id} = attrs, %ClientSchema{name: client_schema, attrs: admin}) do
    change =
      Repo.get(Charge, id, prefix: client_schema)
      |> Charge.changeset(attrs)

    if Enum.any?([:from_date, :to_date, :amount], &change.changes[&1]) do
      put_edits(change, attrs, admin.name)
    else
      attrs
    end
  end

  defp maybe_put_edits(attrs, _admin), do: attrs

  defp do_update_charges(%ClientSchema{name: client_schema, attrs: charge_attrs}) do
    charge_attrs
    |> Enum.with_index()
    |> Enum.reduce(
      Multi.new(),
      fn {charge, index}, multi ->
        Multi.insert_or_update(
          multi,
          :"charge_#{index}",
          insert_or_update_charge(ClientSchema.new(client_schema, charge)),
          prefix: client_schema
        )
      end
    )
    |> Multi.run(
      :deleted,
      fn _repo, cs ->
        charge_ids =
          Map.values(cs)
          |> Enum.map(& &1.id)

        lease_id = hd(charge_attrs).lease_id

        r =
          from(c in Charge, where: c.id not in ^charge_ids and c.lease_id == ^lease_id)
          |> Repo.delete_all(prefix: client_schema)

        {:ok, r}
      end
    )
    |> Repo.transaction()
  end

  defp insert_or_update_charge(%ClientSchema{name: client_schema, attrs: %{id: id} = attrs}) do
    Repo.get(Charge, id, prefix: client_schema)
    |> Charge.changeset(attrs)
  end

  defp insert_or_update_charge(%ClientSchema{attrs: attrs}) do
    %Charge{}
    |> Charge.changeset(attrs)
  end

  defp put_edits(%{changes: changes}, attrs, _) when changes == %{}, do: attrs

  defp put_edits(%{changes: changes} = change, attrs, admin) do
    changed_attrs =
      changes
      |> Map.take([:from_date, :to_date, :amount])
      |> Map.merge(%{admin: admin, time: AppCount.current_time()})

    edits = change.data.edits ++ [changed_attrs]
    Map.merge(attrs, %{edits: edits})
  end

  defp validate_params(params) do
    rent_code = AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:rent)
    hap_rent_code = AppCount.Ledgers.Utils.SpecialChargeCodes.get_charge_code(:hap_rent)

    rent_charges =
      Enum.filter(params, &Enum.member?([rent_code.id, hap_rent_code.id], &1.charge_code_id))

    cond do
      Enum.empty?(rent_charges) ->
        {:error, "No rent charge"}

      Enum.all?(rent_charges, &Map.get(&1, :to_date)) ->
        {:error, "Must have at least one open ended rent charge"}

      true ->
        params
    end
  end
end
