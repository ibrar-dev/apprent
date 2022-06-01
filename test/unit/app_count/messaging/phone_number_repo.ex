defmodule AppCount.Messaging.PhoneNumberRepoTest do
  use AppCount.DataCase
  alias AppCount.Messaging.PhoneNumberRepo

  setup do
    [builder, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.get([:property])

    params = %{
      property_id: property.id,
      number: nil,
      context: nil
    }

    ~M[builder, params]
  end

  test "create/1 valid params", ~M[params] do
    {:ok, res} =
      %{params | number: "+11234567890", context: "test"}
      |> PhoneNumberRepo.create()

    assert res.property_id == params.property_id
    assert res.number == "+11234567890"
  end

  test "correctly formats number", ~M[params] do
    {:ok, res} =
      %{params | number: "1234567890", context: "test"}
      |> PhoneNumberRepo.create()

    assert res.property_id == params.property_id
    assert res.number == "+11234567890"
  end

  test "number uniqueness", ~M[params] do
    %{params | number: "1234567890", context: "all"}
    |> PhoneNumberRepo.create()

    {:error, res} =
      %{params | number: "1234567890", context: "payments"}
      |> PhoneNumberRepo.create()

    assert res.errors == [
             number:
               {"number already in use",
                [
                  constraint: :unique,
                  constraint_name: "messaging__phone_numbers_number_index"
                ]}
           ]
  end

  # Happy Path = context matches
  test "get_number/2 happy path", ~M[params] do
    {:ok, new_num} =
      %{params | number: "1234567890", context: "test"}
      |> PhoneNumberRepo.create()

    res = PhoneNumberRepo.get_number(params.property_id, "test")

    assert new_num == res
  end

  test "get_number/2 returns all when context no matching", ~M[params] do
    {:ok, all_num} =
      %{params | number: "1234567890", context: "all"}
      |> PhoneNumberRepo.create()

    %{params | number: "0987654321", context: "test"}
    |> PhoneNumberRepo.create()

    res = PhoneNumberRepo.get_number(params.property_id, "gibberish")

    assert all_num == res
  end

  test "get_number/2 returns nil when no matching" do
    res = PhoneNumberRepo.get_number(123, "gibberish")

    assert is_nil(res)
  end
end
