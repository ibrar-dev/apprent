defmodule AppCount.RentApply.RentApplicationTest do
  use AppCount.Case
  alias AppCount.RentApply.RentApplication

  test "lease_holdering_person/1" do
    person01 = %AppCount.RentApply.Person{status: "Occupant", full_name: "Occupant1"}
    person02 = %AppCount.RentApply.Person{status: "Occupant", full_name: "Occupant2"}

    lease_holder = %AppCount.RentApply.Person{
      status: "Lease Holder",
      full_name: "The Lease Holder"
    }

    rent_application = %RentApplication{persons: [person01, person02, lease_holder]}
    # When
    actual = RentApplication.lease_holdering_person(rent_application)

    assert actual == lease_holder
  end
end
