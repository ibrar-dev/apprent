defmodule AppCount.Properties.RegionsTest do
  use AppCount.DataCase
  alias AppCount.Properties
  @moduletag :properties_regions

  test "region CRUD" do
    supervisor = AppCount.UserHelper.new_admin()
    Properties.create_region(%{"name" => "Region", "regional_supervisor_id" => supervisor.id})
    region = Repo.get_by(Properties.Region, name: "Region", regional_supervisor_id: supervisor.id)
    assert region
    Properties.update_region(region.id, %{"name" => "New Region"})
    assert Repo.get(Properties.Region, region.id).name == "New Region"
    assert [%{id: region.id, name: "New Region"}] == Properties.list_regions()
  end
end
