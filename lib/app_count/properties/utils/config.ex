defmodule AppCount.Properties.Utils.Config do
  import Ecto.Query
  alias AppCount.Properties.Property
  alias AppCount.Repo

  def check_property_configuration(property_ids) do
    Enum.reduce_while(
      property_ids,
      true,
      fn property_id, _ ->
        case property_is_configured(property_id) do
          true -> {:cont, true}
          e -> {:halt, e}
        end
      end
    )
  end

  defp property_is_configured(property_id) do
    property =
      from(
        p in Property,
        where: p.id == ^property_id,
        left_join: s in assoc(p, :setting),
        left_join: ba in assoc(p, :bank_accounts),
        left_join: r in assoc(p, :registers),
        left_join: pr in assoc(p, :processors),
        select: p,
        preload: [
          registers: r,
          bank_accounts: ba,
          setting: s,
          processors: pr
        ]
      )
      |> Repo.one()

    property
    |> verify(:registers)
    |> verify(:bank_account)
    |> verify(:terms)
    |> verify(:api_credentials)
    |> verify(:final)
  end

  def verify({:error, e}, _), do: {:error, e}

  def verify(property, field) do
    apply(__MODULE__, :"verify_#{field}", [property])
  end

  def verify_registers(%{registers: registers} = property) do
    registers
    |> Enum.filter(& &1.is_default)
    |> length
    |> case do
      3 -> property
      _ -> {:error, "Accounts not configured for #{property.name}"}
    end
  end

  def verify_bank_account(%{setting: s} = property) do
    if s.default_bank_account_id,
      do: property,
      else: {:error, "No e-payment bank account for #{property.name}"}
  end

  def verify_terms(%{terms: ""} = p), do: {:error, "No terms and conditions set for #{p.name}"}
  def verify_terms(property), do: property

  def verify_api_credentials(%{processors: processors} = property) do
    processors
    |> Enum.filter(fn processor ->
      !Enum.any?(processor.keys, &(&1 == "failed decrypt"))
    end)
    |> length
    |> case do
      4 -> property
      5 -> property
      _ -> {:error, "API credentials not properly configured for #{property.name}"}
    end
  end

  def verify_final(_), do: true
end
