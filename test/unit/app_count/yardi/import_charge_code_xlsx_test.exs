defmodule AppCount.Yardi.ImportChargeCodeXlsxCase do
  use AppCount.DataCase
  alias AppCount.Yardi.ImportChargeCodeXlsx
  alias AppCount.Ledgers.ChargeCode
  @moduletag :yardi_import_charge_code_xlsx

  setup do
    insert(:account, num: 42_130_025)
    insert(:account, num: 41_630_000)
    insert(:account, num: 42_150_009)
    insert(:account, num: 42_130_001)
    insert(:account, num: 42_150_014)
    insert(:property, external_id: "1000")
    {:ok, []}
  end

  test "imports charge codes" do
    Path.expand("../../resources/Yardi/charge_codes.xlsx", __DIR__)
    |> ImportChargeCodeXlsx.perform_import()

    assert Repo.get_by(ChargeCode, code: "5day", name: "Five Day Certified Notice Fees")
    assert Repo.get_by(ChargeCode, code: "abatment", name: "Credit for Unit in Abatement")
    assert Repo.get_by(ChargeCode, code: "access", name: "Access Card Clicker Fees")
    assert Repo.get_by(ChargeCode, code: "amenity", name: "Amenity Income")
  end
end
