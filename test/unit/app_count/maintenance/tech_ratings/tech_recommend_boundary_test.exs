defmodule AppCount.Maintenance.TechRecommendBoundaryTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.TechRecommendBoundary
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.TechRepo
  alias AppCount.Core.ClientSchema

  #
  #    WorkOrder ->* Category *<- Skill ->* Tech
  #

  describe "Work order not found, no recommendations" do
    test "recommend/1" do
      work_order_id = 99
      result = TechRecommendBoundary.recommend(work_order_id)

      assert result == []
    end
  end

  defmodule BoundaryParrot do
    use TestParrot
    parrot(:tech_rec, :points_for_all, [])
  end

  describe "two_most_skilled" do
    test "no techs" do
      # When
      result = TechRecommendBoundary.two_most_skilled([], BoundaryParrot)

      assert result == []
      refute_receive :skill_points
    end

    test "one tech" do
      tech = %Tech{}
      BoundaryParrot.say_points_for_all([{44, tech}])
      # When
      result = TechRecommendBoundary.two_most_skilled([tech], BoundaryParrot)

      assert result == [tech]
      assert_receive {:points_for_all, _}
    end

    test "two techs" do
      tech01 = %Tech{id: 1}
      tech02 = %Tech{id: 2}
      BoundaryParrot.say_points_for_all([{11, tech01}, {22, tech02}])
      # When
      result = TechRecommendBoundary.two_most_skilled([tech01], BoundaryParrot)

      assert result == [tech01, tech02]
      assert_receive {:points_for_all, _}
    end

    test "tops two of the three sorted techs" do
      tech01 = %Tech{id: 1}
      tech02 = %Tech{id: 2}
      tech03 = %Tech{id: 3}
      BoundaryParrot.say_points_for_all([{11, tech01}, {33, tech03}, {22, tech02}])
      # When
      result = TechRecommendBoundary.two_most_skilled([tech01], BoundaryParrot)

      assert result == [tech01, tech02]
      assert_receive {:points_for_all, _}
    end
  end

  describe "workorder with category and one tech" do
    setup do
      [_builder, tech, work_order, category] =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.add_tech()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()
        |> PropBuilder.get([:tech, :work_order, :category])

      ~M[ tech, work_order, category ]
    end

    test "recommend the only existing tech with skill", ~M[ tech, work_order, category ] do
      AppCount.Maintenance.TechRepo.add_skill(tech, category)

      # When
      [recommended_tech_01] = TechRecommendBoundary.recommend(work_order.id)

      assert recommended_tech_01.id == tech.id
    end

    test "no recommend tech has NO skills", ~M[ work_order ] do
      # When
      recommended_techs = TechRecommendBoundary.recommend(work_order.id)

      assert recommended_techs == []
    end
  end

  describe "workorder with category and THREE skilled techs" do
    setup do
      [builder, tech01, work_order, category, admin, property] =
        PropBuilder.new()
        |> PropBuilder.add_property()
        |> PropBuilder.add_admin_with_access()
        |> PropBuilder.add_tech(name: "Jimmy")
        |> PropBuilder.add_unit()
        |> PropBuilder.add_unit_category()
        |> PropBuilder.add_work_order_on_unit()
        |> PropBuilder.get([:tech, :work_order, :category, :admin, :property])

      # do not save state
      [_builder, tech02] =
        builder
        |> PropBuilder.add_tech(name: "Tommy")
        |> PropBuilder.get([:tech])

      # do not save state
      [_builder, tech03] =
        builder
        |> PropBuilder.add_tech()
        |> PropBuilder.get([:tech])

      techs = %{tech01: tech01, tech02: tech02, tech03: tech03}

      [tech01, tech02, tech03]
      |> Enum.each(fn tech ->
        AppCount.Maintenance.TechRepo.add_skill(tech, category)
      end)

      ~M[builder, techs, work_order, category, admin, property]
    end

    test "recommend random 2 of 3 techs with zero current assigned orders", ~M[ property] do
      all_techs = TechRepo.for_property(ClientSchema.new("dasmen", property.id))

      # When
      recommended_techs = TechRecommendBoundary.two_most_available(all_techs)

      recommended_tech_ids =
        recommended_techs
        |> Enum.map(fn tech -> tech.id end)

      # random 2 of the 3 tech chosen
      assert 2 == recommended_tech_ids |> length()
    end

    test "recommend tech02 and tech03, because tech01 has a pending assignment ",
         ~M[ builder, techs,  admin, property] do
      # Given

      # adds assignment to tech01
      builder = builder |> PropBuilder.add_work_order_assignment()

      create_open_unit_work_order(techs.tech02, builder, admin)
      create_open_unit_work_order(techs.tech03, builder, admin)

      all_techs = TechRepo.for_property(ClientSchema.new("dasmen", property.id))

      # When
      recommended_techs = TechRecommendBoundary.two_most_available(all_techs)

      recommended_tech_ids =
        recommended_techs
        |> Enum.map(fn tech -> tech.id end)

      # Then
      assert 2 == recommended_tech_ids |> length()
      assert recommended_tech_ids |> Enum.member?(techs.tech02.id)
      assert recommended_tech_ids |> Enum.member?(techs.tech03.id)
    end
  end

  def create_open_unit_work_order(tech, builder, admin) do
    # Note: does not keep order or tech in the PropertyBuilder struct.
    # we throw away all record of the results, except in the DB
    from = naive_now() |> NaiveDateTime.add(-4 * 60 * 60, :second)

    builder
    |> PropBuilder.put_requirement(:tech, tech)
    |> PropBuilder.create_open_unit_work_order(from, admin)

    :ok
  end
end
