defmodule AppCount.Public.ClientRepoTest do
  use AppCount.DataCase
  alias AppCount.Public.ClientRepo

  setup do
    [_builder, client] =
      PropBuilder.new(:create)
      |> PropBuilder.add_client()
      |> PropBuilder.get([:client])

    ~M[client]
  end

  test "from_schema/1 returns nil" do
    res = ClientRepo.from_schema("gibberish")

    assert is_nil(res)
  end

  test "from_schema/1 returns client", ~M[client] do
    res = ClientRepo.from_schema(client.client_schema)

    assert res.name == client.name
    assert res.client_schema == client.client_schema
  end
end
