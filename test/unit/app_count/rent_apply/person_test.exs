defmodule AppCount.RentApply.PersonTest do
  use AppCount.Case, async: true
  alias AppCount.RentApply.Person

  @most_attrs %{
    "cell_phone" => "(653) 642-5316",
    "dl_number" => "123545",
    "dl_state" => "MH",
    "dob" => "1997-02-09",
    "email" => "somebody@gmail.com",
    "home_phone" => "(543) 212-5354",
    "ssn" => "333-22-1111",
    "status" => "Lease Holder",
    "work_phone" => "(625) 613-4556"
  }

  test "wrong status" do
    params = %{@most_attrs | "status" => "Invalid Status"}
    # When
    changeset =
      %Person{}
      |> Person.changeset(params)

    # Then
    refute_valid(changeset)
    assert "is invalid" in errors_on(changeset).status
  end

  test "changeset(%Person{}, attrs)" do
    # When
    changeset01 =
      %Person{}
      |> Person.changeset(@most_attrs)

    # Then
    assert changeset01.errors == [
             application_id: {"can't be blank", [validation: :required]},
             full_name: {"can't be blank", [validation: :required]}
           ]
  end

  test "validation_changeset(changeset, attrs)" do
    # When 01
    changeset01 =
      %Person{}
      |> Person.validation_changeset(@most_attrs)

    # Then 01
    assert changeset01.errors == [
             full_name: {"can't be blank", [validation: :required]}
           ]

    # Given 02
    rest_attrs = %{"full_name" => "Some Body"}

    changeset01 = %{changeset01 | errors: []}

    # When 02
    changeset02 =
      changeset01
      |> Person.validation_changeset(rest_attrs)

    # Then 02
    assert changeset02.errors == []
  end
end
