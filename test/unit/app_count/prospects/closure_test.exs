defmodule AppCount.Prospects.ClosureTest do
  use AppCount.DataCase
  alias AppCount.Prospects
  alias AppCount.Prospects.Closure
  use Bamboo.Test, shared: true
  @moduletag :prospects_closures

  setup do
    closure = insert(:closure)
    property = insert(:property)
    {:ok, closure: closure, property: property}
  end

  test "create closure works", %{property: property} do
    params = %{
      "date" => Timex.shift(AppCount.current_date(), days: 1),
      "start_time" => 780,
      "end_time" => 900,
      "reason" => "Lunch Retreat",
      "admin" => "User 1",
      "property_id" => property.id
    }

    {:ok, c} = Prospects.create_closure(params)
    result = Repo.get(Closure, c.id)
    assert result.date == Timex.shift(AppCount.current_date(), days: 1)
    assert result.start_time == 780
    assert result.end_time == 900
    assert result.reason == "Lunch Retreat"
    assert result.admin == "User 1"
  end

  test "update closure works", %{closure: closure} do
    Prospects.update_closure(closure.id, %{reason: "BC I SAID SO"})
    result = Repo.get(Closure, closure.id)
    assert result.reason == "BC I SAID SO"
  end

  test "cannot set end time before start time", %{closure: closure} do
    end_time = closure.start_time - 60
    Prospects.update_closure(closure.id, %{end_time: end_time})
    result = Repo.get(Closure, closure.id)
    assert result.end_time == closure.end_time
  end

  test "delete closure works", %{closure: closure} do
    Prospects.delete_closures(closure.id)
    result = Repo.get(Closure, closure.id)
    assert is_nil(result)
  end

  test "send email works" do
    showing = insert(:showing, date: Timex.shift(AppCount.current_date(), days: 2))

    params = %{
      "date" => Timex.shift(AppCount.current_date(), days: 2),
      "start_time" => 0,
      "end_time" => 1400,
      "reason" => "Lunch Retreat",
      "admin" => "User 1",
      "property_id" => showing.property_id
    }

    Prospects.create_closure(params)
    assert Repo.get(Prospects.Showing, showing.id)

    # Performed in a Task, so it should be a separate test.
    # assert_email_delivered_with(
    #   subject: "[AppRent] A tour you have scheduled needs to be re-scheduled"
    # )
  end

  test "list affected showings works", %{property: property} do
    insert(:showing, property: property, date: AppCount.current_date())
    date = AppCount.current_date()
    result = Prospects.list_affected_showings(property.id, date)
    assert length(result) == 1
  end

  test "create closure for all properties", %{property: property} do
    prop = insert(:property)

    params = %{
      "date" => Timex.shift(AppCount.current_date(), days: 1),
      "start_time" => 0,
      "end_time" => 1400,
      "reason" => "Holidays n Stuff",
      "admin" => "User 1"
    }

    Prospects.create_closure(params, :all)
    result1 = Prospects.list_closures(prop.id)
    result2 = Prospects.list_closures(property.id)
    assert length(result1) == 1
    assert length(result2) == 1
  end
end
