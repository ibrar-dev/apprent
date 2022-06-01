defmodule AppCount.Maintenance.Utils.Queries.V1.TechsTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.Queries.V1.Techs
  alias AppCountAuth.Users.Admin
  alias AppCount.Core.ClientSchema

  setup do
    times =
      AppTime.new()
      |> AppTime.start_of_month()
      |> AppTime.to_naive(:start_of_month)
      |> AppTime.times()

    [builder, admin, property, tech, parent_category, category] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin_with_access()
      |> PropBuilder.add_property_setting()
      |> PropBuilder.add_tech()
      |> PropBuilder.add_parent_category()
      |> PropBuilder.add_category()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_unit_category()
      |> PropBuilder.get([:admin, :property, :tech, :parent_category, :category])

    # insert(:job, property: property, tech: tech)
    skill = insert(:skill, tech: tech, category: category)
    client = AppCount.Public.get_client_by_schema("dasmen")

    [_builder, work_order, assignment] =
      builder
      # accepted
      |> PropBuilder.create_property_work_order(times.start_of_month, admin, client.client_schema)
      |> PropBuilder.exec_accept_assignment()
      |> PropBuilder.get([:work_order, :assignment])

    builder
    # withdrawn
    |> PropBuilder.create_property_work_order(times.start_of_month, admin, client.client_schema)
    |> PropBuilder.exec_rate_assignment(2)
    |> PropBuilder.exec_reject_assignment()
    # callback
    |> PropBuilder.create_property_work_order(times.start_of_month, admin, client.client_schema)
    |> PropBuilder.exec_rate_assignment(2)
    |> PropBuilder.exec_callback_assignment()
    # completed
    |> PropBuilder.create_property_work_order(times.start_of_month, admin, client.client_schema)
    |> PropBuilder.exec_rate_assignment(3)
    |> PropBuilder.exec_complete_assignment(client.client_schema)

    [_builder, other_property] =
      builder
      |> PropBuilder.add_property()
      |> PropBuilder.get([:property])

    %{
      admin: %Admin{property_ids: [property.id]},
      assignment: assignment,
      category: category,
      other_property: other_property,
      parent_category: parent_category,
      property: property,
      skill: skill,
      tech: tech,
      work_order: work_order
    }
  end

  describe "list_techs/1" do
    test "returns a list of summarized techs", %{admin: admin, tech: tech} do
      result = Techs.list_techs(ClientSchema.new("dasmen", admin))

      assert Enum.count(result) == 1

      [record] = result
      assert(record.id == tech.id)
    end
  end

  # describe "show_tech/2" do
  #   test "returns a single tech", %{admin: admin, tech: tech} do
  #     record = Techs.show_tech(admin, tech.id)

  #     assert(record.id == tech.id)
  #   end
  # end

  # describe "update_tech/3" do
  #   test "updates a tech", %{admin: admin, tech: tech} do
  #     attributes = %{name: "updated", email: "sample@test.com", phone_number: "1231231234"}

  #     {:ok, _result} = Techs.update_tech(admin, tech.id, attributes)

  #     updated_tech = Techs.get_tech(admin, tech.id)
  #     assert(updated_tech.name == attributes.name)
  #     assert(updated_tech.email == attributes.email)
  #     assert(updated_tech.phone_number == attributes.phone_number)
  #   end

  #   test "updates a tech's associated skills", %{
  #     admin: admin,
  #     tech: tech,
  #     parent_category: parent_category
  #   } do
  #     attributes = %{"category_ids" => [parent_category.id]}

  #     {:ok, _result} = Techs.update_tech(admin, tech.id, attributes)

  #     updated_tech = Techs.get_tech(admin, tech.id)
  #     assert(Enum.count(updated_tech.skills) == 1)
  #     assert(List.first(updated_tech.skills).category.id == parent_category.id)
  #   end

  #   test "updates a tech's associated jobs", %{
  #     admin: admin,
  #     tech: tech,
  #     other_property: other_property,
  #     property: property
  #   } do
  #     attributes = %{"property_ids" => [property.id, other_property.id]}

  #     {:ok, _result} = Techs.update_tech(admin, tech.id, attributes)

  #     updated_tech = Techs.get_tech(admin, tech.id)
  #     assert(Enum.count(updated_tech.jobs) == 2)
  #     assert(Enum.any?(updated_tech.jobs, &(&1.property.id == property.id)))
  #     assert(Enum.any?(updated_tech.jobs, &(&1.property.id == other_property.id)))
  #   end
  # end

  # describe "needed_data/1" do
  #   test "returns a minimal tech representation", %{admin: admin, tech: tech} do
  #     result =
  #       Techs.get_tech(admin, tech.id)
  #       |> Techs.needed_data()

  #     assert(result.active == tech.active)

  #     %{metrics: metrics} = result
  #     assert(metrics.assigned == 1)
  #     assert(metrics.withdrawn == 1)
  #     assert(metrics.callbacks == 1)
  #     assert(metrics.completed == 1)
  #     assert(metrics.rating == 7 / 3)
  #   end
  # end

  # describe "detail_data/1" do
  #   test "returns a detailed tech representation", %{admin: admin, tech: tech} do
  #     result =
  #       Techs.get_tech(admin, tech.id)
  #       |> Techs.detail_data()

  #     assert(result.active == tech.active)
  #     assert(Map.has_key?(result, :assignments))
  #     assert(Map.has_key?(result, :top_skills))
  #     assert(Map.has_key?(result, :skills))

  #     %{metrics: metrics} = result
  #     assert(metrics.assigned == 1)
  #     assert(metrics.withdrawn == 1)
  #     assert(metrics.callbacks == 1)
  #     assert(metrics.completed == 1)
  #     assert(metrics.rating == 7 / 3)
  #     # TODO: assert metrics.tech_score == something

  #     # TODO: skills/category
  #   end

  #   test "returns a detailed parent category representation", %{parent_category: parent_category} do
  #     result = Techs.detail_data(parent_category)

  #     assert(result.name == parent_category.name)
  #   end

  #   test "returns a detailed child category representation", %{category: category} do
  #     result = Techs.detail_data(category)

  #     assert(result.name == category.name)
  #     assert(Map.has_key?(result, :parent))
  #   end

  #   test "returns a detailed skill representation", %{skill: skill} do
  #     result = Techs.detail_data(skill)

  #     assert(result.id == skill.id)
  #   end

  #   test "returns a detailed assignment representation", %{assignment: assignment} do
  #     result = Techs.detail_data(assignment)

  #     assert(result.status == assignment.status)
  #   end

  #   test "returns a detailed order representation", %{work_order: work_order} do
  #     result =
  #       work_order
  #       |> Repo.preload([:property])
  #       |> Techs.detail_data()

  #     assert(Map.has_key?(result, :property))
  #   end

  #   test "returns a detailed property representation", %{property: property} do
  #     result = Techs.detail_data(property)

  #     assert(result.name == property.name)
  #   end

  #   test "returns empty when record not provided" do
  #     result = Techs.detail_data(nil)

  #     assert(result == %{})
  #   end
  # end
end
