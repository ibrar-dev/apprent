defmodule MoneyGramTest do
  use AppCount.Case

  @moduletag :moneygram

  def validation_request() do
    File.read!(Path.expand("../../resources/moneygram/validation_request.xml", __DIR__))
  end

  def validation_response do
    File.read!(Path.expand("../../resources/moneygram/validation_response.xml", __DIR__))
  end

  def failure_response do
    File.read!(Path.expand("../../resources/moneygram/failure_response.xml", __DIR__))
  end

  def load_request do
    File.read!(Path.expand("../../resources/moneygram/load_request.xml", __DIR__))
  end

  def load_response do
    File.read!(Path.expand("../../resources/moneygram/load_response.xml", __DIR__))
  end

  test "generic process request" do
    assert {:ok, "1010123456789"} == MoneyGram.process_request(validation_request())

    assert {:ok, %{account_number: "1010123456789", amount: 100.0, ref_number: "12345678"}} ==
             MoneyGram.load_request(load_request())
  end

  test "processes validation request" do
    assert {:ok, "1010123456789"} == MoneyGram.validation_request(validation_request())
  end

  test "sends validation responses" do
    resp =
      MoneyGram.validation_response(
        status: "PASS",
        transaction_id: "123456789",
        message: "SUCCESS"
      )

    assert String.replace(validation_response(), ~r"(\s\s+)|\n", "") == resp

    resp =
      MoneyGram.validation_response(
        status: "FAIL",
        transaction_id: "957864123",
        error_code: "1010",
        message: "NO SUCH ACCOUNT"
      )

    assert String.replace(failure_response(), ~r"(\s\s+)|\n", "") == resp
  end

  test "processes load request" do
    assert {:ok, %{account_number: "1010123456789", amount: 100.0, ref_number: "12345678"}} ==
             MoneyGram.load_request(load_request())
  end

  test "sends load response" do
    resp =
      MoneyGram.load_response(status: "PASS", transaction_id: "957864123", message: "SUCCESS")

    assert String.replace(load_response(), ~r"(\s\s+)|\n", "") == resp
  end
end
