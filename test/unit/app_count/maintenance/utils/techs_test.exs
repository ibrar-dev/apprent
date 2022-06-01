defmodule AppCount.Maintenance.Utils.TechsTest do
  use AppCount.DataCase
  alias AppCount.Maintenance
  alias AppCount.Maintenance.TechRepo
  alias AppCount.Core.ClientSchema

  @moduletag :utils_techs

  setup do
    property = insert(:property)
    tech = insert(:job, property: property).tech

    admin = %AppCountAuth.Users.Admin{
      client_schema: "dasmen",
      property_ids: [property.id],
      roles: MapSet.new([])
    }

    {:ok, property: property, tech: tech, admin: admin}
  end

  describe "CRUD " do
    test "create_tech", %{property: property} do
      category = insert(:category)
      insert(:category)

      params = %{
        "name" => "Weird Al",
        "property_ids" => [property.id],
        "category_ids" => [category.id],
        "email" => "techguy@example.com",
        "phone_number" => "1234567890",
        "type" => "Tech"
      }

      Maintenance.create_tech(params)

      tech =
        TechRepo.get_by(name: params["name"])
        |> Repo.preload([:jobs, :categories])

      assert hd(tech.jobs).property_id == property.id
      assert hd(tech.categories).id == category.id
    end

    test "update_tech", %{tech: tech} do
      category = insert(:category)

      ClientSchema.new(tech.__meta__.prefix, tech.id)
      |> Maintenance.update_tech(%{"name" => "Weird Al", "category_ids" => [category.id]})

      reloaded =
        TechRepo.get(tech.id)
        |> Repo.preload(:categories)

      assert reloaded.name == "Weird Al"
      assert Enum.map(reloaded.categories, & &1.id) == [category.id]

      insert(:category)

      ClientSchema.new(tech.__meta__.prefix, tech.id)
      |> Maintenance.update_tech(%{"name" => "Weird Al", "category_ids" => []})

      reloaded =
        TechRepo.get(tech.id)
        |> Repo.preload(:categories)

      assert length(reloaded.categories) == 2

      ClientSchema.new(tech.__meta__.prefix, tech.id)
      |> Maintenance.update_tech(%{"name" => "Weird Al", "category_ids" => [category.id]})

      reloaded =
        TechRepo.get(tech.id)
        |> Repo.preload(:categories)

      assert length(reloaded.categories) == 1

      ClientSchema.new(tech.__meta__.prefix, tech.id)
      |> Maintenance.update_tech(%{"name" => "Weird Al", "property_ids" => []})

      reloaded =
        TechRepo.get(tech.id)
        |> Repo.preload(:jobs)

      assert reloaded.jobs == []
    end

    test "delete_tech", %{tech: tech} do
      Maintenance.delete_tech(tech.id)
      refute TechRepo.get(tech.id)
    end
  end

  test "list_techs/1", %{admin: admin, tech: tech} do
    [result] = Maintenance.list_techs(ClientSchema.new("dasmen", admin))
    assert result.email == tech.email
    assert result.id == tech.id
  end

  test "list_techs(admin, :min)", %{admin: admin, tech: tech, property: property} do
    [result] = Maintenance.list_techs(ClientSchema.new("dasmen", admin), :min)
    assert result.name == tech.name
    assert result.id == tech.id
    assert hd(result.property_ids) == property.id
  end

  test "list_techs(admin, :tech) super admin", %{admin: admin, tech: tech, property: property} do
    [result] =
      ClientSchema.new(
        "dasmen",
        Map.put(admin, :roles, ["Super Admin"])
      )
      |> Maintenance.list_techs(:tech)

    assert result.name == tech.name
    assert result.id == tech.id
    assert hd(result.property_ids) == property.id

    [
      :active,
      :can_edit,
      :category_ids,
      :description,
      :email,
      :id,
      :image,
      :lat,
      :lng,
      :month_stats,
      :name,
      :pass_code,
      :phone_number,
      :presence,
      :property_ids,
      :require_image,
      :stats,
      :type
    ]
    |> Enum.each(&assert Map.has_key?(result, &1))
  end

  test "list_techs(admin, :tech)", %{admin: admin, tech: tech, property: property} do
    [result] = Maintenance.list_techs(ClientSchema.new("dasmen", admin), :tech)
    assert result.name == tech.name
    assert result.id == tech.id
    assert hd(result.property_ids) == property.id

    [
      :active,
      :can_edit,
      :category_ids,
      :description,
      :email,
      :id,
      :image,
      :lat,
      :lng,
      :month_stats,
      :name,
      :pass_code,
      :phone_number,
      :presence,
      :property_ids,
      :require_image,
      :stats,
      :type
    ]
    |> Enum.each(&assert Map.has_key?(result, &1))
  end

  test "list_techs(admin, :loc)", %{admin: admin, tech: tech} do
    [result] = Maintenance.list_techs(ClientSchema.new("dasmen", admin), :loc)
    assert result.name == tech.name
    assert result.id == tech.id

    [:id, :image, :lat, :lng, :presence]
    |> Enum.each(&assert Map.has_key?(result, &1))
  end

  test "list_techs(admin, :assign)", %{admin: admin, tech: tech, property: property} do
    [result] = Maintenance.list_techs(ClientSchema.new("dasmen", admin), :assign)
    assert result.name == tech.name
    assert result.id == tech.id
    assert hd(result.property_ids) == property.id

    [
      :assignments,
      :category_ids,
      :email,
      :id,
      :image,
      :month_stats,
      :name,
      :phone_number,
      :property_ids,
      :stats,
      :type
    ]
    |> Enum.each(&assert Map.has_key?(result, &1))
  end

  test "tech_details", %{tech: tech} do
    now = AppCount.current_time()

    insert(:assignment,
      tech: tech,
      rating: 4,
      status: "completed",
      completed_at: now,
      confirmed_at: Timex.shift(now, days: -2)
    )

    insert(:assignment,
      tech: tech,
      rating: 2,
      status: "completed",
      completed_at: now,
      confirmed_at: Timex.shift(now, days: -4)
    )

    result =
      ClientSchema.new(tech.__meta__.prefix, tech.id)
      |> Maintenance.tech_details()

    assert Decimal.to_integer(result.rating) == 3
    assert result.completion_time.days == 3
  end

  test "set_tech_coords", %{tech: tech} do
    coords = %{lat: 90, lng: 90}

    %AppCount.Core.ClientSchema{name: "dasmen", attrs: tech.id}
    |> Maintenance.set_tech_coords(coords)

    assert Agent.get(:tech_tracking, & &1)[tech.id] == coords
  end

  test "set_pass_code", %{tech: tech} do
    Maintenance.set_pass_code(tech.id)
    assert byte_size(TechRepo.get(tech.id).pass_code) == 36
  end

  test "tech_detailed_info", %{tech: tech} do
    result = Maintenance.tech_detailed_info(ClientSchema.new("dasmen", tech.id))
    assert result.email == tech.email
    assert result.id == tech.id
    assert length(Map.keys(result)) == 14
  end

  test "tech_info", %{tech: tech} do
    result =
      ClientSchema.new(tech.__meta__.prefix, tech.id)
      |> Maintenance.tech_info()

    assert result.email == tech.email
    assert result.id == tech.id
    assert length(Map.keys(result)) == 9
  end

  test "tech_data", %{tech: tech} do
    assert Maintenance.tech_data(ClientSchema.new(tech.__meta__.prefix, tech.id)).assignments ==
             []
  end

  test "tech_order_data", %{tech: tech} do
    order = insert(:assignment, tech: tech).order

    result =
      ClientSchema.new(tech.__meta__.prefix, tech.id)
      |> Maintenance.tech_order_data(order.id)

    assert length(result.assignments) == 1
    assert length(Map.keys(result)) == 17
  end

  test "last_six_months", %{tech: tech} do
    result = Maintenance.last_six_months(ClientSchema.new("dasmen", tech.id))
    assert length(result) == 6

    result
    |> List.first()
    |> Map.keys()
    |> length
    |> Kernel.==(7)
    |> assert
  end

  test "log_on and log_off", %{tech: tech} do
    prefix = tech.__meta__.prefix
    schema = ClientSchema.new(prefix, tech.id)
    Maintenance.log_on(schema)
    assert Repo.get_by(Maintenance.PresenceLog, [tech_id: tech.id, present: true], prefix: prefix)
    Maintenance.log_off(schema)
    refute Repo.get_by(Maintenance.PresenceLog, [tech_id: tech.id, present: true], prefix: prefix)
  end

  @tag :flaky
  test "get_active_techs", %{tech: tech, admin: admin} do
    today = AppCount.current_time() |> Timex.end_of_day()
    insert(:assignment, tech: tech, status: "completed")

    assert Maintenance.get_active_techs(ClientSchema.new("dasmen", admin), today) == [
             %{id: tech.id, name: tech.name}
           ]
  end

  test "set_all_categories", %{tech: tech} do
    [cat1, cat2] = [insert(:category), insert(:category)]
    Maintenance.set_all_categories(ClientSchema.new("dasmen", tech.id))

    Repo.preload(tech, :categories)
    |> Map.get(:categories)
    |> Enum.map(& &1.id)
    |> Enum.sort()
    |> Kernel.==([cat1.id, cat2.id])
    |> assert
  end
end
