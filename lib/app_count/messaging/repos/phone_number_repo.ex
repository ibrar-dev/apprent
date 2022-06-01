defmodule AppCount.Messaging.PhoneNumberRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Messaging.PhoneNumber,
    preloads: [:property]

  alias AppCount.Core.PhoneNumber

  def create(%{number: number} = params) do
    number =
      number
      |> PhoneNumber.new()
      |> PhoneNumber.dial_string()

    %{params | number: number}
    |> insert()
  end

  def get_number(property_id) do
    from(
      n in @schema,
      where: n.property_id == ^property_id and n.context == "all",
      limit: 1
    )
    |> Repo.one()
  end

  def get_number(property_id, context) do
    from(
      n in @schema,
      where: n.property_id == ^property_id and n.context == ^context,
      limit: 1
    )
    |> Repo.one()
    |> case do
      nil -> get_number(property_id)
      num -> num
    end
  end
end
