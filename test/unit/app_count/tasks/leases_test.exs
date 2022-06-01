defmodule AppCount.LeasesTaskTest do
  use AppCount.DataCase
  import AppCount.{TimeCop, LeaseHelper}
  import Ecto.Query
  alias AppCount.Leases.Lease
  alias AppCount.Ledgers
  alias AppCount.Support.HTTPClient
  @moduletag :leases_tasks

  setup do
    start = %Date{year: 2019, day: 15, month: 3}
    end_date = %Date{year: 2020, day: 14, month: 3}
    charges = [rent: 500]

    lease =
      insert_lease(%{
        start_date: start,
        end_date: end_date,
        charges: charges,
        pending_bluemoon_lease_id: "15151515",
        pending_bluemoon_signature_id: "161616161",
        unit:
          insert(:unit,
            number: "409",
            features: [insert(:feature, price: 800), insert(:feature, price: 600)]
          )
      })

    insert(:processor, name: "BlueMoon", property: lease.unit.property)
    {:ok, [lease: lease]}
  end

  test "poll_for_signatures for renewals", %{lease: lease} do
    sources = Path.expand("../../resources/BlueMoon", __DIR__)

    [
      "/CreateSessionIn.xml",
      "/GetLeaseXMLData.xml",
      "/CreateSessionIn.xml",
      "/GetEsignatureData.xml",
      "/CreateSessionIn.xml",
      "/ExecuteLease.xml",
      "/CreateSessionIn.xml",
      "/GetEsignaturePDF.xml"
    ]
    |> Enum.map(&File.read!(sources <> &1))
    |> HTTPClient.initialize()

    AppCount.Tasks.Workers.PollForLeaseSignatures.perform()
    reloaded = Repo.get(Lease, lease.id)
    assert reloaded.renewal_id
    refute reloaded.pending_bluemoon_lease_id
    refute reloaded.pending_bluemoon_signature_id

    assert Repo.get_by(
             Lease,
             id: reloaded.renewal_id,
             bluemoon_lease_id: "15151515",
             bluemoon_signature_id: "161616161"
           )

    HTTPClient.stop()
  end

  test "poll_for_signatures adjusts charges for renewals", %{lease: lease} do
    date =
      Timex.shift(lease.end_date, months: 1)
      |> Timex.end_of_month()

    sources = Path.expand("../../resources/BlueMoon", __DIR__)

    [
      "/CreateSessionIn.xml",
      "/GetLeaseXMLData.xml",
      "/CreateSessionIn.xml",
      "/GetEsignatureData.xml",
      "/CreateSessionIn.xml",
      "/ExecuteLease.xml",
      "/CreateSessionIn.xml",
      "/GetEsignaturePDF.xml"
    ]
    |> Enum.map(&File.read!(sources <> &1))
    |> HTTPClient.initialize()

    freeze date do
      AppCount.Tasks.Workers.Charges.perform(lease.unit.property.id, date)

      rent_charge_query =
        from(
          c in Ledgers.Charge,
          join: cc in assoc(c, :charge_code),
          where: c.lease_id == ^lease.id and cc.code == "rent",
          select: type(c.amount, :float),
          order_by: [
            asc: c.amount
          ]
        )

      assert Repo.all(rent_charge_query) == [1400]
      AppCount.Tasks.Workers.PollForLeaseSignatures.perform()
      AppCount.Tasks.Workers.Charges.perform(lease.unit.property.id, date)
      assert Repo.all(rent_charge_query) == [-700, 1400]

      rent_charge_query =
        from(
          c in Ledgers.Charge,
          join: cc in assoc(c, :charge_code),
          where: c.lease_id == ^(lease.id + 1) and cc.code == "rent",
          select: type(c.amount, :float)
        )

      assert Repo.all(rent_charge_query) == [550]
    end

    HTTPClient.stop()
  end
end
