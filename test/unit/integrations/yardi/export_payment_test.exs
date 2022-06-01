defmodule Yardi.Gateway.ExportPaymentCase do
  use AppCount.Case
  alias AppCount.Support.HTTPClient
  @moduletag :yardi_gateway_export_payment

  @payment_success File.read!(
                     Path.expand(
                       "../../resources/Yardi/export_payment_success.xml",
                       __DIR__
                     )
                   )

  @payment_failure File.read!(
                     Path.expand(
                       "../../resources/Yardi/export_payment_failure.xml",
                       __DIR__
                     )
                   )

  def options() do
    credentials = %{
      username: "",
      password: "",
      platform: "",
      server_name: "",
      db: "",
      url: "",
      entity: "",
      interface: "",
      gl_account: ""
    }

    %{
      property_id: "1x1x",
      credentials: credentials,
      property_name: "Test Property",
      transaction_id: "123456",
      payment_id: "111222",
      customer_id: "t001234",
      amount: 1234.50,
      payment_date: ~D[2021-01-01]
    }
  end

  test "export_payment raises with incomplete options" do
    full_options =
      options()
      |> Map.put(:payment_date, nil)

    message = "Missing required values for Yardi payment import: #{inspect(full_options)}"

    assert_raise RuntimeError, message, fn ->
      HTTPClient.initialize([@payment_success])
      Yardi.Gateway.export_payment(full_options)
    end

    HTTPClient.stop()
  end

  test "export_payment success" do
    HTTPClient.initialize([@payment_success])
    result = Yardi.Gateway.export_payment(options())
    HTTPClient.stop()
    assert result == {:ok, "1 receipts were successfully imported into batch 1296679."}
  end

  test "export_payment failure" do
    HTTPClient.initialize([@payment_failure])
    result = Yardi.Gateway.export_payment(options())
    HTTPClient.stop()

    assert result == {
             :error,
             "Message Type=Error. Item Number=0. Payments from this tenant must be cash equivalent. (TranType=Receipt.)\nMessage Type=Error. Item Number=0. Error importing receipt for resident t0016708. Payments from this tenant must be cash equivalent.\nImport Failed.  Review Xml. 'Property Batch' = true\n"
           }
  end
end
