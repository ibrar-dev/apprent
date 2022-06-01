defmodule TenantSafe.GetOrderDecision do
  import XmlBuilder
  alias TenantSafe.Request
  alias TenantSafe.Credentials
  import SweetXml

  def submit(order_id, %Credentials{} = config) do
    build_request(order_id, config)
    |> Request.submit()
    |> case do
      {:ok, body} ->
        body
        |> parse(namespace_conformant: true)
        |> xmap(
          status:
            ~x"//BackgroundReports/BackgroundReportPackage/ScreeningStatus/OrderStatus/text()"S,
          url: ~x"//BackgroundReports/BackgroundReportPackage/ReportURL/text()"S
        )

      {:error, e} ->
        e
    end
  end

  def build_request(order_id, config) do
    element(
      :BackgroundCheck,
      %{userId: config.user_id, password: config.password},
      [
        order_id_element(order_id)
      ]
    )
    |> generate()
  end

  def order_id_element(order_id) do
    element(
      :BackgroundSearchPackage,
      %{action: "status"},
      [
        element(:OrderId, order_id)
      ]
    )
  end
end
