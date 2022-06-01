defmodule AppCount.Properties.Utils.Processors do
  alias AppCount.Repo
  alias AppCount.Properties.Processor
  alias Payscape.CreateAccount
  import Ecto.Query
  require Logger
  alias AppCount.Core.ClientSchema

  def list_processors() do
    from(p in Processor,
      select:
        map(p, [
          :id,
          :type,
          :keys,
          :name,
          :login,
          :password,
          :property_id
        ])
    )
    |> Repo.all()
  end

  def list_processors(%ClientSchema{name: client_schema}) do
    from(p in Processor,
      select:
        map(p, [
          :id,
          :type,
          :keys,
          :name,
          :login,
          :password,
          :property_id
        ])
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_processor(%ClientSchema{name: client_schema, attrs: params}) do
    %Processor{}
    |> Processor.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  @spec create_payscape_account_and_processor(%ClientSchema{attrs: map}, map) ::
          {:ok, %Processor{}} | {:error, %Ecto.Changeset{}} | {:error, String.t()}
  def create_payscape_account_and_processor(
        %ClientSchema{name: client_schema, attrs: account},
        params
      ) do
    create_account = Enum.into(account, %{}, fn {k, v} -> {String.to_existing_atom(k), v} end)

    case CreateAccount.create(
           %{keys: Enum.concat(params["keys"], [""])},
           struct(CreateAccount, create_account)
         ) do
      {:ok, %{"Status" => "00"} = response} ->
        keys = Enum.concat(params["keys"], [response["AccountNumber"]])

        new_params = %{
          "keys" => keys,
          "login" => response["SourceEmail"],
          "password" => response["Password"]
        }

        %Processor{}
        |> Processor.changeset(Map.merge(params, new_params))
        |> Repo.insert(
          prefix: client_schema,
          on_conflict: {:replace_all_except, [:id, :property_id, :type]},
          conflict_target: [:property_id, :type]
        )

      {:ok, response} ->
        {:error, "Error status: #{response["Status"]}"}

      e ->
        Logger.error(inspect(e))
        e
    end
  end

  @spec update_processor(%ClientSchema{attrs: integer}, map) ::
          {:ok, %Processor{}} | {:error, %Ecto.Changeset{}}
  def update_processor(%ClientSchema{name: client_schema, attrs: id}, params) do
    Repo.get(Processor, id)
    |> Processor.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  @spec delete_processor(%ClientSchema{attrs: integer}) ::
          {:ok, %Processor{}} | {:error, %Ecto.Changeset{}}
  def delete_processor(%ClientSchema{name: client_schema, attrs: id}) do
    Repo.get(Processor, id)
    |> Repo.delete(prefix: client_schema)
  end

  @spec get_bluemoon_property_ids(%ClientSchema{attrs: integer()}) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_bluemoon_property_ids(%ClientSchema{name: client_schema, attrs: processor_id}) do
    [serial, user, password | _] =
      from(
        p in Processor,
        where: p.id == ^processor_id,
        select: p.keys
      )
      |> Repo.one(prefix: client_schema)

    %BlueMoon.Credentials{serial: serial, user: user, password: password}
    |> BlueMoon.list_properties()
  end

  def can_instant_screen(property_id) do
    setting_query =
      from(
        s in AppCount.Properties.Setting,
        where: s.instant_screen == true,
        where: s.property_id == ^property_id,
        select: %{
          id: s.id,
          property_id: s.property_id
        }
      )

    processor_query =
      from(
        p in Processor,
        where: p.type == "screening",
        where: p.property_id == ^property_id,
        select: %{
          id: p.id,
          property_id: p.property_id
        }
      )

    from(
      p in AppCount.Properties.Property,
      join: s in subquery(setting_query),
      on: s.property_id == p.id,
      join: proc in subquery(processor_query),
      on: proc.property_id == p.id,
      select: true
    )
    |> Repo.one()
  end
end
