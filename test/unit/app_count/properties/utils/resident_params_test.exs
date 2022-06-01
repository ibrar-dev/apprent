defmodule AppCount.Properties.Utils.ResidentParamsTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Properties.Utils.ResidentParams

  @moduletag :resident_params

  setup do
    template = insert(:letter_template)
    %{tenants: [tenant], end_date: end_date} = insert_lease(%{property: template.property})
    letter1 = insert(:recurring_letter, letter_template: template)

    letter2 =
      insert(:recurring_letter,
        letter_template: template,
        resident_params: %{current: false, future: true}
      )

    letter3 =
      insert(:recurring_letter,
        letter_template: template,
        resident_params: %{lease_end_date: Timex.shift(end_date, days: -1)}
      )

    {:ok, letter1: letter1, letter2: letter2, letter3: letter3, tenant: tenant}
  end

  test "get_residents", %{letter1: letter1, letter2: letter2, letter3: letter3, tenant: tenant} do
    [result] = ResidentParams.get_residents(letter1.id)
    assert result == tenant.id
    assert ResidentParams.get_residents(letter2.id) == []
    assert ResidentParams.get_residents(letter3.id) == []
  end
end
