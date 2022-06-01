defmodule AppCountWeb.API.ErrorView do
  defmacro __using__(_) do
    quote do
      def render("error.json", assigns) do
        errors =
          Enum.reduce(assigns.errors, %{}, fn {field, detail}, acc ->
            Map.put_new(acc, field, render_detail(detail))
          end)

        %{errors: errors}
      end

      def render_detail({message, values}) do
        Enum.reduce(values, message, fn {k, v}, acc ->
          String.replace(acc, "%{#{k}}", to_string(v))
        end)
      end

      def render_detail(message) do
        message
      end
    end
  end
end
