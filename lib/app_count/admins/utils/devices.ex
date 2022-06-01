defmodule AppCount.Admins.Utils.Devices do
  alias AppCount.Admins.Device
  alias AppCount.Admins.DeviceAuth
  alias AppCount.Repo
  import Ecto.Query
  import AppCount.EctoExtensions

  def list_devices(%AppCount.Core.ClientSchema{
        name: client_schema
      }) do
    from(
      d in Device,
      left_join: a in assoc(d, :device_auths),
      select: map(d, [:id, :name, :private_cert]),
      select_merge: %{
        property_ids: array(a.property_id)
      },
      group_by: d.id
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_device(nil, _), do: nil

  def get_device(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: id
        },
        identifier
      ) do
    Repo.get_by(Device, [id: id, identifier: identifier], prefix: client_schema)
  end

  def update_device(
        id,
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: %{"property_ids" => property_ids} = params
        }
      ) do
    attach_properties(
      id,
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }
    )

    update_device(
      id,
      %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: Map.delete(params, "property_ids")
      }
    )
  end

  def update_device(id, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Repo.get(Device, id, prefix: client_schema)
    |> Device.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_device(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    Repo.get(Device, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  defp attach_properties(id, %AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: property_ids
       }) do
    from(
      d in DeviceAuth,
      where: d.device_id == ^id and d.property_id not in ^property_ids
    )
    |> Repo.delete_all(prefix: client_schema)

    Enum.each(
      property_ids,
      fn pid ->
        %DeviceAuth{}
        |> DeviceAuth.changeset(%{device_id: id, property_id: pid})
        |> Repo.insert(prefix: client_schema)
      end
    )
  end
end
