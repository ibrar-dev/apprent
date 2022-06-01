defmodule AppCount.Properties.ProcessorsTest do
  use AppCount.DataCase
  import Mock
  alias AppCount.Properties
  alias AppCount.Support.HTTPClient
  alias AppCount.Core.ClientSchema
  @moduletag :processors

  setup do
    property = insert(:property)
    {:ok, property: property}
  end

  test "create_payscape_account_and_processor", %{property: property} do
    processor = %{
      "name" => "Payscape",
      "keys" => ["cert", "term"],
      "type" => "ba",
      "property_id" => property.id
    }

    account = %{
      "email" => "man@building.com",
      "phone" => "1234567890",
      "business_name" => "Acme Widgets",
      "address" => "123 Main St.",
      "city" => "SomeTown",
      "state" => "NY",
      "zip" => "52525",
      "account_name" => "Edward Smith",
      "account_number" => "2654856",
      "routing_number" => "15236545",
      "bank_name" => "Wells Fargo",
      "account_type" => "Checking",
      "account_ownership_type" => "Business",
      "ein" => "256457845"
    }

    response = """
    {
      "AccountNumber": 123456,
      "BeneficialOwnerDataResult": [],
      "Password": "TempPassw0rd",
      "SourceEmail": "someguy@someproperty.com",
      "Status": "00",
      "Tier": "Consolidated"
    }
    """

    with_mock HTTPoison,
              [:passthrough],
              request: fn _, _, _, _, _ -> {:ok, %HTTPoison.Response{body: response}} end do
      Properties.create_payscape_account_and_processor(
        ClientSchema.new("dasmen", account),
        processor
      )

      processor = Repo.get_by(Properties.Processor, property_id: property.id)
      assert processor.keys == ["cert", "term", "123456"]
      assert processor.type == "ba"
      assert processor.name == "Payscape"
    end
  end

  test "list_processors", %{property: property} do
    {:ok, _processor} =
      Properties.create_processor(
        ClientSchema.new(
          "dasmen",
          %{
            "name" => "Authorize",
            "type" => "cc",
            "property_id" => property.id,
            "keys" => ["123456", "7891011", "12131415"],
            "login" => "some_login"
          }
        )
      )

    result = Properties.list_processors(ClientSchema.new("dasmen"))
    assert length(result) == 1
    assert hd(result).keys == ["123456", "7891011", "12131415"]
    assert hd(result).login == "some_login"
  end

  test "processor_credentials", %{property: property} do
    {:ok, _processor} =
      Properties.create_processor(
        ClientSchema.new(
          "dasmen",
          %{
            "name" => "Authorize",
            "type" => "cc",
            "property_id" => property.id,
            "keys" => ["123456", "7891011", "12131415"],
            "login" => "some_login"
          }
        )
      )

    result =
      Properties.Processors.processor_credentials(ClientSchema.new("dasmen", property.id), "cc")

    assert result.api_key == "123456"
    assert result.transaction_key == "7891011"
    assert result.public_key == "12131415"
  end

  test "processor CRUD", %{property: property} do
    {:ok, processor} =
      Properties.create_processor(
        ClientSchema.new(
          "dasmen",
          %{
            "name" => "Authorize",
            "type" => "cc",
            "property_id" => property.id,
            "keys" => ["123456", "7891011", "12131415"]
          }
        )
      )

    assert length(processor.keys) == 3

    {:ok, updated} =
      Properties.update_processor(ClientSchema.new("dasmen", processor.id), %{
        "keys" => ["abcdefg", "7891011", "12131415"]
      })

    updated = Repo.get(Properties.Processor, updated.id)
    assert hd(updated.keys) == "abcdefg"
    Properties.delete_processor(ClientSchema.new("dasmen", processor.id))
    refute Repo.get(Properties.Processor, processor.id)
  end

  test "get_bluemoon_property_ids" do
    processor = insert(:processor, type: "lease", name: "Bluemoon", keys: ["a", "b", "c"])
    sources = Path.expand("../../../resources/BlueMoon", __DIR__)

    ["/CreateSessionIn.xml", "/ListProperties.xml"]
    |> Enum.map(&File.read!(sources <> &1))
    |> HTTPClient.initialize()

    result = Properties.get_bluemoon_property_ids(ClientSchema.new("dasmen", processor.id))
    assert result == {:ok, [%{id: "9607", name: "Property Name Prints Here - PA", type: "aptdb"}]}
    HTTPClient.stop()
  end
end
