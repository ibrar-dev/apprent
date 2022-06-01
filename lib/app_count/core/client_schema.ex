defmodule AppCount.Core.ClientSchema do
  @derive {Jason.Encoder, only: [:name, :attrs]}
  defstruct name: :not_set, attrs: :not_set

  def new(name, attrs) do
    %AppCount.Core.ClientSchema{name: name, attrs: attrs}
  end

  def new(%{client_schema: client_schema} = admin), do: new(client_schema, admin)

  def new(client_schema) when is_binary(client_schema), do: new(client_schema, nil)
end
