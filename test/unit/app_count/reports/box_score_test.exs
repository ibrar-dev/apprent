defmodule AppCount.Accounts.BoxScoreTest do
  use AppCount.Case
  @moduletag :boxscore

  #  @start_date %Date{year: 2018, month: 5, day: 2}
  #  @end_date %Date{year: 2019, month: 5, day: 2}
  #  @charges [Rent: 900, Admin: 100, Pet: 50, Concession: -50]

  # ALL OF THESE TESTS NEED TO BE RE-WRITTEN FOR THE FINAL UPDATE TO THE BOX SCORE. BUT CONSIDERING THESE FUNCTIONS ARE NO LONGER RELEVANT...

  #  setup do
  #    property = insert(:property)
  #    admin = admin_with_access([property.id])
  #    tenants = [insert(:tenant), insert(:tenant)]
  #    {:ok, %{property: property, admin: admin, tenants: tenants}}
  #  end
  #
  #  test "find_move_in unit test", %{property: property, admin: admin, tenants: tenants} do
  #    new_lease =
  #      insert_lease(%{
  #        start_date: @start_date,
  #        expected_move_in: @start_date,
  #        end_date: @end_date,
  #        charges: @charges,
  #        tenants: tenants,
  #        actual_move_in: @start_date,
  #        unit: insert(:unit, property: property)
  #      })
  #
  #    move_ins =
  #      BoxScore.find_move_in(admin, property.id, %Date{year: 2018, month: 5, day: 1}, %Date{
  #        year: 2018,
  #        month: 5,
  #        day: 3
  #      })
  #
  #    assert length(move_ins) == 1
  #    assert List.first(move_ins).id == new_lease.id
  #  end
  #
  #  test "find_move_out unit_test", %{property: property, admin: admin, tenants: tenants} do
  #    new_lease =
  #      insert_lease(%{
  #        start_date: @start_date,
  #        expected_move_in: @start_date,
  #        end_date: @end_date,
  #        charges: @charges,
  #        tenants: tenants,
  #        actual_move_in: @start_date,
  #        actual_move_out: @end_date,
  #        unit: insert(:unit, property: property)
  #      })
  #
  #    move_outs =
  #      BoxScore.find_move_out(admin, property.id, %Date{year: 2019, month: 5, day: 1}, %Date{
  #        year: 2019,
  #        month: 5,
  #        day: 3
  #      })
  #
  #    assert length(move_outs) == 1
  #    assert List.first(move_outs).id == new_lease.id
  #  end
  #
  #  test "renewal unit_test", %{property: property, admin: admin, tenants: tenants} do
  #    unit = insert(:unit, property: property)
  #
  #    old_lease =
  #      insert_lease(%{
  #        start_date: %Date{year: 2018, month: 5, day: 20},
  #        expected_move_in: %Date{year: 2018, month: 5, day: 20},
  #        end_date: %Date{year: 2019, month: 5, day: 20},
  #        charges: @charges,
  #        tenants: tenants,
  #        actual_move_in: @start_date,
  #        actual_move_out: %Date{year: 2018, month: 5, day: 20},
  #        unit: unit
  #      })
  #
  #    insert_lease(%{
  #      start_date: %Date{year: 2019, month: 5, day: 21},
  #      expected_move_in: %Date{year: 2019, month: 5, day: 21},
  #      end_date: %Date{year: 2020, month: 5, day: 21},
  #      charges: @charges,
  #      tenants: tenants,
  #      actual_move_in: %Date{year: 2019, month: 5, day: 21},
  #      unit: unit
  #    })
  #
  #    renewals =
  #      BoxScore.renewal(admin, property.id, %Date{year: 2019, month: 5, day: 20}, %Date{
  #        year: 2019,
  #        month: 5,
  #        day: 22
  #      })
  #
  #    assert length(renewals) == 1
  #    assert List.first(renewals).id == old_lease.id
  #  end
  #
  #  test "evictions unit_test", %{property: property, admin: admin, tenants: tenants} do
  #    new_lease = insert_lease(
  #      %{
  #          start_date: %Date{year: 2018, month: 5, day: 21},
  #          expected_move_in: %Date{year: 2018, month: 5, day: 21},
  #          end_date: %Date{year: 2020, month: 5, day: 21},
  #          charges: @charges,
  #          tenants: tenants,
  #          actual_move_in: %Date{year: 2018, month: 5, day: 21},
  #          unit: insert(:unit, property: property)
  #       }
  #    )
  #    file_date = %Date{year: 2019, month: 1, day: 1}
  #    court_date = %Date{year: 2019, month: 1, day: 19}
  #    new_evict = insert(:eviction, lease: new_lease, file_date: file_date, court_date: court_date)
  #    evictions = BoxScore.find_evictions(admin, property.id, %Date{year: 2018, month: 12, day: 25}, %Date{year: 2019, month: 1, day: 25})
  #    assert length(evictions) == length(tenants)
  #    assert List.first(evictions).id == new_evict.id
  #  end
  #
  #  test "month_to_month unit_test", %{property: property, admin: admin, tenants: tenants} do
  #    lease =
  #      insert_lease(%{
  #        start_date: %Date{year: 2018, month: 5, day: 21},
  #        expected_move_in: %Date{year: 2018, month: 5, day: 21},
  #        end_date: %Date{year: 2019, month: 5, day: 21},
  #        charges: @charges,
  #        tenants: tenants,
  #        actual_move_in: %Date{year: 2018, month: 5, day: 21},
  #        unit: insert(:unit, property: property)
  #      })
  #
  #    month_to_month =
  #      BoxScore.month_to_month(admin, property.id, %Date{year: 2019, month: 5, day: 20}, %Date{
  #        year: 2019,
  #        month: 6,
  #        day: 1
  #      })
  #
  #    assert length(month_to_month) == 1
  #    assert List.first(month_to_month).id == lease.id
  #  end
  #
  #  test "find_tours unit_test", %{property: property, admin: admin} do
  #    prospect = insert(:prospect, property: property)
  #    showing = insert(:showing, prospect: prospect, property: property, date: %Date{year: 2019, month: 5, day: 21})
  #    tours = BoxScore.find_tours(admin, property.id, %Date{year: 2019, month: 5, day: 10}, %Date{year: 2019, month: 6, day: 1})
  #    assert length(tours) == 1
  #    assert List.first(tours).id == showing.id
  #  end
  #
  #  test "find_payments unit_test", %{property: property, admin: admin} do
  #    creation_date = "2019-05-21 07:56:40"
  #    application = insert(:rent_application)
  #    payment = insert(:payment, description: "Application Fee", property: property, inserted_at: creation_date, application_id: application.id)
  #    start_date = "2019-05-20 07:56:40"
  #    end_date = "2019-06-02 07:56:40"
  #    application_payments = BoxScore.find_payments(admin, property.id, start_date, end_date)
  #    assert length(application_payments) == 1
  #    assert payment.application_id == application.id
  #  end
  #
  #  test "find_applicants unit_test", %{property: property, admin: admin} do
  #    creation_date = "2019-05-21 07:56:40"
  #    ra = insert(:rent_application, property: property, inserted_at: creation_date)
  #    pers = insert(:rent_apply_person, application: ra)
  #    start_date = "2019-05-20 07:56:40"
  #    end_date = "2019-06-02 07:56:40"
  #    applicants = BoxScore.find_applicants(admin, property.id, start_date, end_date)
  #    assert length(applicants) == 1
  #    assert List.first(applicants).application_id == ra.id
  #    assert List.first(applicants).id == pers.id
  #  end
end
