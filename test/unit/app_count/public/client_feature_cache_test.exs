# defmodule AppCount.Public.ClientFeaturesCacheTest do
#  use AppCount.DataCase
#  alias AppCount.Repo
#  alias AppCount.Public.ClientFeaturesCache
#  alias AppCount.Public.ClientFeature
#
#  @tag skip: "missing feature insertion"
#  test "Getting a user from client features cache " do
#    id =
#      from(
#        cf in ClientFeature,
#        select: %{
#          client_id: cf.client_id
#        },
#        limit: 1
#      )
#      |> Repo.all()
#      |> Enum.fetch!(0)
#      |> Map.fetch!(:client_id)
#      |> to_string()
#
#    refute ClientFeaturesCache.get("client_#{id}") == {:not_found}
#  end
#
#  test "Adding a user to the client features cache" do
#    user = %{"client_3" => %{"Payment" => true}}
#    ClientFeaturesCache.set(user)
#
#    assert ClientFeaturesCache.set(user) == {:reply, user}
#  end
# end
