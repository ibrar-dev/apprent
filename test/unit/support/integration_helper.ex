defmodule AppCountWeb.IntegrationHelper do
  use ExUnit.CaseTemplate

  using do
    quote do
      @test_adapters AppCount.adapters()

      def setup_adapters do
        prod_adapters = Keyword.put(@test_adapters, :pub_sub, Phoenix.PubSub)

        Application.put_env(:app_count, :adapters, prod_adapters)
        on_exit(fn -> Application.put_env(:app_count, :adapters, @test_adapters) end)
      end
    end
  end
end
