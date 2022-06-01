defmodule AppCount.RentApply.ValidatableBehaviour do
  @callback validation_changeset(map(), map()) :: Ecto.Changeset.t()

  # # example:
  # # ComponentBehaviour.validate_changeset(PersonComponent, changeset, attrs)
  # def validate_changeset(implementation, changeset, attrs) do
  #   case implementation.changeset(changeset, attrs) do
  #     {:ok, data} -> data
  #     {:error, error} -> raise ArgumentError, "parsing error: #{error}"
  #   end
  # end
end
