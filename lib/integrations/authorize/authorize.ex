defmodule Authorize do
  @moduledoc """
  Authorize a transaction. Currently accepts:

  + Credit card (raw data)
  + Token (1-time payments)
  + Customer profile (any payments)
  """
  alias Authorize.URL
  alias Authorize.CreateTransaction
  import SweetXml

  @headers [{"Content-Type", "text/xml"}]

  def process_payment(amount, source, processor) do
    req =
      CreateTransaction.request(amount, source, processor)
      |> XmlBuilder.generate()

    AppCount.Core.HTTPClient.post(URL.url(), req, @headers)
    |> process_response()
  end

  def process_response({:error, error}) do
    {:error, error}
  end

  def process_response({:ok, %HTTPoison.Response{body: body}}) do
    parse_response(body)
    |> extract_data()
  end

  def extract_data(%{approval: "1", result_code: "Ok"} = params) do
    {:ok, Map.take(params, [:transaction_id, :account_number, :auth_code])}
  end

  def extract_data(%{result_code: "Error", error_code: "E00003"}) do
    {:error, %{reason: "Invalid Card Number."}}
  end

  def extract_data(%{result_code: "Error", error_code: "E00007"}) do
    {:error, %{reason: "Bad authentication values. Please contact support immediately."}}
  end

  def extract_data(%{result_code: "Error", error_code: "E000059"}) do
    {:error,
     %{
       reason:
         "There was an issue processing this payment. Please wait a moment and then try again."
     }}
  end

  def extract_data(%{error: error, result_code: "Error"}) do
    {:error, %{reason: error}}
  end

  def extract_data(%{error: error, result_code: "Ok"}) do
    {:error, %{reason: error}}
  end

  def extract_data(params) do
    {:error, params}
  end

  def parse_response(body) do
    body
    |> parse(namespace_conformant: true)
    |> xmap(
      account_number: ~x"//transactionResponse/accountNumber/text()"S,
      approval: ~x"//transactionResponse/messages/message/code/text()"S,
      auth_code: ~x"//transactionResponse/authCode/text()"S,
      avs_result_code: ~x"//transactionResponse/avsResultCode/text()"S,
      cvv_result_code: ~x"//transactionResponse/cvvResultCode/text()"S,
      error: ~x"//transactionResponse/errors/error/errorText/text()"S,
      error_code: ~x"//messages/message/code/text()"S,
      result_code: ~x"//messages/resultCode/text()"S,
      transaction_id: ~x"//transactionResponse/transId/text()"S
    )
  end
end
