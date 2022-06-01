defmodule AppCount.Properties.PropertyRepoTest do
  use AppCount.DataCase
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Core.DateTimeRange
  alias AppCount.Properties
  alias AppCount.Properties.Processor
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.PropertyTopic
  alias AppCount.Core.ClientSchema

  def add_tenant(prop_builder) do
    prop_builder =
      prop_builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()

    tenant = PropBuilder.get_requirement(prop_builder, :tenant)
    {prop_builder, tenant}
  end

  describe "create_property/1" do
    setup do
      params = %{
        name: "Test Property-on-mars",
        code: "prop-on-mars",
        address: %{
          zip: "28205",
          street: "3317 Magnolia Hill Dr",
          state: "NC",
          city: "Charlotte"
        },
        terms: "These are my terms, take 'em or leave 'em",
        social: %{}
      }

      ~M[params]
    end

    test "creates in DB", ~M[params] do
      # Given
      original_count = PropertyRepo.count()

      # When
      Properties.create_property(ClientSchema.new("dasmen", params))

      # Then
      actual_count = PropertyRepo.count()
      assert actual_count == original_count + 1
    end

    test "create publishes event", ~M[params] do
      # Given
      PropertyTopic.subscribe()

      # When
      Properties.create_property(ClientSchema.new("dasmen", params))

      # Then
      assert_receive %DomainEvent{
        topic: "property",
        name: "property_created",
        content: %{property_id: _property_id},
        source: AppCount.Properties.PropertyRepo
      }
    end
  end

  describe "credit_card_payment_processor/1" do
    setup do
      [_builder, property] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get([:property])

      ~M[property]
    end

    test "gets ZERO", ~M[property] do
      # When
      result = PropertyRepo.credit_card_payment_processor(property.id)

      assert {:error, _message} = result
    end

    test "error response with nil property ID" do
      assert {:error, _message} = PropertyRepo.credit_card_payment_processor(nil)
    end

    test "error response with non-integer property ID" do
      assert {:error, _message} =
               PropertyRepo.credit_card_payment_processor(
                 "this is not an integer by any definition"
               )
    end

    test "gets 1", ~M[property] do
      keys = ["123456", "7891011", "12131415"]

      {:ok, processor} =
        Properties.create_processor(
          ClientSchema.new(
            "dasmen",
            %{
              "name" => "Authorize",
              "type" => "cc",
              "property_id" => property.id,
              "keys" => keys
            }
          )
        )

      # When
      {:ok, cc_processor} = PropertyRepo.credit_card_payment_processor(property.id)

      # then
      processor_id = processor.id

      assert %Processor{id: ^processor_id, keys: ^keys, name: "Authorize", type: "cc"} =
               cc_processor
    end
  end

  describe "bank_account_payment_processor/1" do
    setup do
      [_builder, property] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get([:property])

      ~M[property]
    end

    test "gets ZERO", ~M[property] do
      # When
      bank_account_processor = PropertyRepo.bank_account_payment_processor(property.id)

      assert {:error, _message} = bank_account_processor
    end

    test "error response with nil property ID" do
      assert {:error, _message} = PropertyRepo.bank_account_payment_processor(nil)
    end

    test "error response with non-integer property ID" do
      assert {:error, _message} = PropertyRepo.bank_account_payment_processor("abcdefg")
    end

    test "gets 1", ~M[property] do
      keys = ["123456", "038746", "939743"]

      {:ok, _processor} =
        Properties.create_processor(
          ClientSchema.new(
            "dasmen",
            %{
              "name" => "Payscape",
              "type" => "ba",
              "property_id" => property.id,
              "keys" => keys
            }
          )
        )

      # When
      {:ok, bank_account_processor} = PropertyRepo.bank_account_payment_processor(property.id)
      processor_id = bank_account_processor.id

      # Then
      assert %Processor{id: ^processor_id, keys: ^keys, name: "Payscape", type: "ba"} =
               bank_account_processor
    end
  end

  describe "active_property_ids" do
    setup do
      [builder, inactive_property1] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_property_setting(active: false)
        |> PropBuilder.get([:property])

      [builder, active_property2] =
        builder
        |> PropBuilder.add_property()
        |> PropBuilder.add_property_setting(active: true)
        |> PropBuilder.get([:property])

      ~M[builder, inactive_property1, active_property2]
    end

    test "all", ~M[inactive_property1, active_property2] do
      # When
      result =
        PropertyRepo.active_property_ids(
          ClientSchema.new(
            "dasmen",
            %{}
          )
        )

      # Then
      refute Enum.member?(result, inactive_property1.id)
      assert Enum.member?(result, active_property2.id)
    end
  end

  describe "property_ids" do
    setup do
      [builder, property1] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get([:property])

      [_builder, property2] =
        builder
        |> PropBuilder.add_property()
        |> PropBuilder.get([:property])

      ~M[property1, property2]
    end

    test "all", ~M[property1, property2] do
      # When
      result = PropertyRepo.property_ids(ClientSchema.new("dasmen"))
      assert Enum.member?(result, property1.id)
      assert Enum.member?(result, property2.id)
    end
  end

  describe "tenants/1" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_tenancy()

      property = PropBuilder.get_requirement(builder, :property)
      tenant = PropBuilder.get_requirement(builder, :tenant)
      date_range = DateTimeRange.year_to_date()

      ~M[builder, property, tenant, date_range]
    end
  end

  describe "settings/1" do
    setup do
      property =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_property_setting()
        |> PropBuilder.get_requirement(:property)

      ~M[property]
    end

    test ":ok", ~M[property] do
      setting = PropertyRepo.setting(property.id)
      assert %AppCount.Properties.Setting{} = setting
    end
  end

  describe "update_property_settings/2" do
    setup do
      property =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      AppCount.Core.PropertyTopic.subscribe()

      ~M[property]
    end

    test "create", ~M[property] do
      refute Ecto.assoc_loaded?(property.setting)
      # When
      property =
        PropertyRepo.update_property_settings(
          property,
          ClientSchema.new(
            "dasmen",
            %{}
          )
        )

      assert Ecto.assoc_loaded?(property.setting)
      assert property.setting.active == true
      assert_received %{name: "property_changed"}
    end

    test "update active", ~M[property] do
      property =
        PropertyRepo.update_property_settings(
          property,
          ClientSchema.new(
            "dasmen",
            %{active: false}
          )
        )

      # When
      setting = PropertyRepo.property_settings(ClientSchema.new("dasmen", property))
      assert setting.active == false
      assert_received %{name: "property_changed"}
    end

    test "update rewards", ~M[property] do
      property =
        PropertyRepo.update_property_settings(
          property,
          ClientSchema.new(
            "dasmen",
            %{rewards: false}
          )
        )

      # When
      setting = PropertyRepo.property_settings(ClientSchema.new("dasmen", property))

      # Then
      property_id = property.id
      assert setting.rewards == false
      assert_received %{name: "property_changed", content: %{property_id: ^property_id}}
    end
  end

  describe "property exists " do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      property =
        builder
        |> PropBuilder.get_requirement(:property)

      expected_property =
        Map.put(
          property,
          :address,
          %{
            "city" => "Charlotte",
            "state" => "NC",
            "street" => "3317 Magnolia Hill Dr",
            "zip" => "28205"
          }
        )

      ~M[property, expected_property, builder]
    end

    test "get/1, loads no assoc", ~M[property, expected_property] do
      found_property = PropertyRepo.get(property.id)

      refute Ecto.assoc_loaded?(found_property.units)
      assert found_property.id == expected_property.id
    end

    test "get_aggregate/1 loads assoc", ~M[property] do
      found_property = PropertyRepo.get_aggregate(property.id)
      assert Ecto.assoc_loaded?(found_property.units)
    end

    test "get_by_property_code!/1", ~M[property, expected_property] do
      # When
      found_property = PropertyRepo.get_by_property_code(property.code)
      refute Ecto.assoc_loaded?(found_property.units)
      assert found_property.id == expected_property.id
    end

    test "get_active_techs/1", ~M[property, builder] do
      tech =
        builder
        |> PropBuilder.add_tech(name: "Hank", active: false)
        |> PropBuilder.add_tech(name: "Joe", active: false)
        |> PropBuilder.add_tech(name: "Harry")
        |> PropBuilder.get_requirement(:tech)

      # When
      [harry] = PropertyRepo.get_active_techs(ClientSchema.new("dasmen", property))

      # Then
      assert harry.identifier
      assert harry.name == "Harry"
      harry = %{harry | identifier: nil}
      assert harry == tech
    end
  end

  describe "completed_cards/2" do
    setup do
      times =
        AppTime.new()
        |> AppTime.plus(:now, days: 0)
        |> AppTime.plus(:three_days_ago, days: -3)
        |> AppTime.plus_to_date(:start_date, days: -30)
        |> AppTime.plus_to_date(:five_days_ago, days: -5)
        |> AppTime.plus_to_date(:a_year_ago, days: -365)
        |> AppTime.plus_to_date(:two_weeks_ago, days: -14)
        |> AppTime.plus_to_date(:three_weeks_ago, days: -21)
        |> AppTime.times()

      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()

      ~M[times, builder]
    end

    test "with no cards at all", ~M[times, builder] do
      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.get_requirement(:property)

      result =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), times.start_date)

      assert [] = result
    end

    test "with one card in range", ~M[times, builder] do
      card_attrs = [
        move_out_date: times.five_days_ago,
        completion: %{
          "date" => DateTime.to_iso8601(times.three_days_ago),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      [card] =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), times.start_date)

      assert card.move_out_date == times.five_days_ago
      assert card.completion["date"] == card_attrs[:completion]["date"]
    end

    test "card out of range", ~M[times, builder] do
      card_attrs = [
        move_out_date: times.a_year_ago,
        completion: %{
          "date" => DateTime.to_iso8601(times.three_days_ago),
          "name" => "blah"
        }
      ]

      expected_result = []

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      result =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), times.start_date)

      assert expected_result == result
    end

    test "with incomplete card", ~M[times, builder] do
      card_attrs = [
        move_out_date: times.a_year_ago,
        completion: nil
      ]

      expected_result = []

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(card_attrs)
        |> PropBuilder.get_requirement(:property)

      result =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), times.start_date)

      assert expected_result == result
    end

    test "multiple cards", ~M[times, builder] do
      first_card_attrs = [
        move_out_date: times.three_weeks_ago,
        completion: %{
          "date" => DateTime.to_iso8601(times.now),
          "name" => "blah"
        }
      ]

      second_card_attrs = [
        move_out_date: times.two_weeks_ago,
        completion: %{
          "date" => DateTime.to_iso8601(times.three_days_ago),
          "name" => "blah"
        }
      ]

      property =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(first_card_attrs)
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card(second_card_attrs)
        |> PropBuilder.get_requirement(:property)

      [card1, card2] =
        PropertyRepo.completed_cards(ClientSchema.new("dasmen", property), times.start_date)

      # Card 1
      assert card1.move_out_date == times.three_weeks_ago
      assert card1.completion["date"] == first_card_attrs[:completion]["date"]
      # Card 2
      assert card2.move_out_date == times.two_weeks_ago
      assert card2.completion["date"] == second_card_attrs[:completion]["date"]
    end
  end

  describe "info_for_email/1" do
    setup do
      [_builder, property] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property(lat: 1, lng: 2)
        |> PropBuilder.get([:property])

      ~M[property]
    end

    test "bare minimum works", ~M[property] do
      res = PropertyRepo.info_for_email(property.id)
      assert res.id
      assert res.name
      assert res.social
      assert res.lat
      assert res.lng
      assert res.phone
      assert res.website
    end
  end
end
