defmodule AppCount.Maintenance.Utils.CardsTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.Utils.Cards
  alias AppCount.Core.ClientSchema
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  @moduletag :cards_utils

  setup do
    [_builder, admin, card, card_item, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin(%{name: "Some Admin"})
      |> PropBuilder.add_unit()
      |> PropBuilder.add_card()
      |> PropBuilder.add_card_item()
      |> PropBuilder.get([:admin, :card, :card_item, :property])

    ~M[admin, card, card_item, property]
  end

  test "list_cards/3 " do
    card_attrs = [hidden: true]

    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_card(card_attrs)

    property = PropBuilder.get_requirement(builder, :property)

    admin =
      admin_with_access([property.id])
      |> Map.merge(%{property_ids: [property.id]})

    # WHEN
    # Ugly
    [result] =
      Cards.list_cards(
        ClientSchema.new(admin.user.client.client_schema, admin),
        [property.id],
        :hidden
      )

    # return an anonymous struct with these keys
    assert Map.keys(result) == [
             :admin,
             :completion,
             :deadline,
             :hidden,
             :id,
             :inserted_at,
             :items,
             :move_in_date,
             :move_out_date,
             :priority,
             :property,
             :unit
           ]
  end

  describe "create_card_item/2" do
    test "with tech" do
      new_admin = AppCount.UserHelper.new_admin()
      client = AppCount.Public.get_client_by_schema("dasmen")

      card = insert(:card)
      admin = new_admin
      # with tech
      {:ok, item} =
        Cards.create_card_item(
          ClientSchema.new(
            client.client_schema,
            %{
              "name" => "Some name",
              "card_id" => card.id,
              "tech_id" => insert(:tech).id
            }
          ),
          admin
        )

      assert item.name == "Some name"
    end

    test "without tech" do
      card = insert(:card)
      admin = AppCount.UserHelper.new_admin()
      client = AppCount.Public.get_client_by_schema("dasmen")

      {:ok, item} =
        Cards.create_card_item(
          ClientSchema.new(
            client.client_schema,
            %{
              "name" => "Some other name",
              "card_id" => card.id
            }
          ),
          admin
        )

      assert item.name == "Some other name"
      client = AppCount.Public.get_client_by_schema("dasmen")
      # with duplicate
      {:error, changeset} =
        Cards.create_card_item(
          ClientSchema.new(
            client.client_schema,
            %{
              "name" => "Some other name",
              "card_id" => card.id
            }
          ),
          admin
        )

      assert length(changeset.errors) == 1
    end
  end

  describe "create_item_order/2" do
    test "handles admin is present", ~M[admin, card_item] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      result =
        Cards.create_item_order(
          ClientSchema.new(client.client_schema, card_item),
          admin
        )
        |> Repo.preload(:card_item)

      refute is_nil(result)
      assert result.card_item == card_item
    end

    test "handles when no admin is present", ~M[card, card_item, admin] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      result =
        Cards.create_item_order(
          ClientSchema.new(
            client.client_schema,
            card_item
          ),
          nil
        )
        |> Repo.preload(:card_item)

      assert card.admin == admin.name
      assert result.card_item == card_item
    end
  end

  test "complete_card_item create" do
    card = insert(:card)
    admin = AppCount.UserHelper.new_admin()

    Cards.complete_card_item(
      "create",
      ClientSchema.new(
        admin.user.client.client_schema,
        %{"card_id" => card.id, "name" => "Punch", "tech_id" => insert(:tech).id}
      ),
      admin
    )

    assert Repo.get_by(
             AppCount.Maintenance.CardItem,
             [
               name: "Punch",
               card_id: card.id,
               status: "Admin Completed",
               completed: AppCount.current_date(),
               completed_by: admin.name
             ],
             prefix: admin.user.client.client_schema
           )
  end
end
