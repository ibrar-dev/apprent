defmodule AppCount.ExternalServiceTest do
  use AppCount.DataCase

  defmodule UnderTest do
    use AppCount.ExternalService, :json_adapter
  end

  alias AppCount.ExternalServiceTest.UnderTest

  test "curl/4" do
    url = "https://sb-api.softledger.com/api/invoices"

    body =
      "{\"currency\":\"USD\",\"LocationId\":876,\"InvoiceLineItems\":[],\"AgentId\":5466,\"ARAccountId\":10_855}"

    header = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer eyJhbGc"}
    ]

    result = UnderTest.dump_curl(:post, url, body, header)

    expected =
      ~s<curl -v post -H "Content-Type: application/json" -H "Authorization: Bearer eyJhbGc" -d '{"currency":"USD","LocationId":876,"InvoiceLineItems":[],"AgentId":5466,"ARAccountId":10_855}' https://sb-api.softledger.com/api/invoices ;>

    assert result == expected
  end

  defmodule StatusResponse do
    defstruct status: 0

    def new(attrs) when is_map(attrs) do
      struct(__MODULE__, attrs)
    end
  end

  alias AppCount.ExternalServiceTest.StatusResponse

  describe "check_status_code/2" do
    test "200" do
      result =
        UnderTest.check_status_code({:ok, %HTTPoison.Response{status_code: 200}}, StatusResponse)

      assert result == {:ok, %AppCount.ExternalServiceTest.StatusResponse{status: 200}}
    end

    test "400" do
      result =
        UnderTest.check_status_code(
          {:ok, %HTTPoison.Response{status_code: 400, body: "body"}},
          StatusResponse
        )

      assert result ==
               {:error, ~s/Parse error: "body"/}
    end

    test "other error" do
      result =
        UnderTest.check_status_code(
          {:ok, %HTTPoison.Response{status_code: 500, body: "body"}},
          StatusResponse
        )

      assert result ==
               {:error,
                ~s/Error: {:ok, %HTTPoison.Response{body: "body", headers: [], request: nil, request_url: nil, status_code: 500}}/}
    end
  end
end
