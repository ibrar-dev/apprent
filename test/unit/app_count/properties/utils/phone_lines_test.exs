defmodule AppCount.Properties.PhoneLinesTest do
  use AppCount.DataCase
  alias AppCount.Properties
  @moduletag :properties_phone_lines

  setup do
    {:ok, property: insert(:property)}
  end

  test "phone_line CRUD", %{property: property} do
    %{"number" => "(555) 555-5555", "property_id" => property.id}
    |> Properties.create_phone_line()

    phone_line =
      Repo.get_by(Properties.PhoneLine, number: "(555) 555-5555", property_id: property.id)

    assert phone_line
    new_number = "(555) 555-5556"
    Properties.update_phone_line(phone_line.id, %{"number" => new_number})
    assert Repo.get(Properties.PhoneLine, phone_line.id).number == new_number
    assert [%{id: phone_line.id, number: new_number}] == Properties.list_phone_lines(property.id)
    Properties.delete_phone_line(phone_line.id)
    refute Repo.get(Properties.PhoneLine, phone_line.id)
  end
end
