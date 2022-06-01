defmodule AppCount.EctoTypes.Attachment do
  defmacro __using__(_) do
    quote do
      import AppCount.EctoTypes.Attachment
    end
  end

  defmacro attachment(name) do
    quote do
      belongs_to unquote(name),
                 Module.concat(["AppCount.Data.Upload"]),
                 foreign_key: String.to_atom("#{unquote(name)}_id")

      belongs_to String.to_atom("#{unquote(name)}_url"),
                 Module.concat(["AppCount.Data.UploadURL"]),
                 source: String.to_atom("#{unquote(name)}_id")
    end
  end

  def cast_attachment(changeset, name, opts \\ []) do
    case changeset.params["#{name}"] do
      %{uuid: uuid} -> do_cast_attachment(uuid, changeset, name, opts)
      %{"uuid" => uuid} -> do_cast_attachment(uuid, changeset, name, opts)
      _ -> changeset
    end
  end

  defp do_cast_attachment(uuid, changeset, name, opts) do
    data_module = Module.concat(["AppCount.Data"])

    changeset
    |> Map.update!(:params, &Map.put(&1, "#{name}", data_module.process_upload(uuid, opts)))
    # pretend we have no previous attachment
    |> Map.update!(:data, &Map.put(&1, name, nil))
    |> Ecto.Changeset.cast_assoc(name)
  end
end
