defmodule AppCountWeb.ViewHelpers do
  defmacro __using__(_) do
    quote do
      import AppCountWeb.Helpers.Currency
      import AppCountWeb.Helpers.Number
    end
  end
end
