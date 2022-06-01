defmodule AppCountAuth.ProviderTest do
  use AppCount.Case
  alias AppCountAuth.Provider

  test "returns authorizer for given controller" do
    assert Provider.authorizer_for(AppCountWeb.JobController, :index) ==
             AppCountAuth.JobController

    assert Provider.authorizer_for(AppCountWeb.NonExistentController, :index) ==
             AppCountAuth.OpenController
  end
end
