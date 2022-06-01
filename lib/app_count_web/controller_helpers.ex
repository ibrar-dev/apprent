defmodule AppCountWeb.ControllerHelpers do
  import Phoenix.Controller, only: [json: 2]
  import Plug.Conn, only: [put_status: 2, put_resp_content_type: 2, send_resp: 3]

  def handle_error({:ok, _result}, conn), do: json(conn, %{})
  def handle_error(result, conn, callback \\ nil)
  def handle_error({:ok, result}, conn, fun), do: json(conn, fun.(result))

  def handle_error({:error, %Ecto.Changeset{} = cs}, conn, _callback) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: convert_cs_error(cs)})
  end

  def handle_error({:error, error}, conn, _callback) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: error})
  end

  def handle_error({:error, field, changeset, _}, conn, _callback) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: String.capitalize("#{field} ") <> convert_cs_error(changeset)})
  end

  def to_boolean("true"), do: true
  def to_boolean("false"), do: false

  def to_integers(comma_sep_numbers) when is_binary(comma_sep_numbers) do
    comma_sep_numbers
    |> String.split(",")
    |> Enum.map(&to_integer/1)
    |> Enum.reject(fn num -> is_nil(num) end)
  end

  defp to_integer("") do
    nil
  end

  defp to_integer(number_as_string) do
    String.to_integer(number_as_string)
  end

  def safe_json(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(conn.status || 200, Jason.encode!(data))
  end

  defp convert_cs_error(%Ecto.Changeset{errors: errors}) do
    {name, {msg, _}} = hd(errors)

    "#{name} #{msg}"
    |> String.capitalize()
    |> String.replace(~r/_/, " ")
  end
end
