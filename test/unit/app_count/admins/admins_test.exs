defmodule AppCount.AdminsTest do
  use AppCount.DataCase
  alias AppCount.Admins
  alias AppCount.Messaging.Bounce
  alias AppCount.Core.ClientSchema

  @moduletag :admins

  setup do
    prop = insert(:property)
    prop2 = insert(:property)
    insert(:property)
    admin = admin_with_access([prop.id])
    {:ok, [admin: admin, property: prop, property_2: prop2]}
  end

  test "property_ids_for", context do
    assert Admins.property_ids_for(ClientSchema.new("dasmen", context.admin)) == [
             context.property.id
           ]
  end

  test "filtered_property_ids_for", context do
    # UNUSED ?

    assert Admins.filtered_property_ids_for(
             ClientSchema.new("dasmen", context.admin),
             [context.property.id]
           ) ==
             [
               context.property.id
             ]

    assert Admins.filtered_property_ids_for(
             ClientSchema.new("dasmen", context.admin),
             [
               context.property.id,
               context.property_2.id
             ]
           ) == [context.property.id]
  end

  test "has_permission?", context do
    assert Admins.has_permission?(ClientSchema.new("dasmen", context.admin), context.property.id)
    new_prop = insert(:property)

    refute Admins.has_permission?(
             ClientSchema.new("dasmen", context.admin),
             new_prop.id
           )

    assert Admins.has_permission?(
             %{roles: MapSet.new(["Super Admin"])},
             new_prop.id
           )
  end

  test "reset password request", context do
    result = Admins.reset_password_request(context.admin.email)
    assert result.html_body =~ "forgot_password?token="
  end

  test "admin not allowed to reset pw", context do
    Admins.update_admin(
      context.admin.id,
      ClientSchema.new(
        context.admin.user.client.client_schema,
        %{reset_pw: false}
      )
    )

    res = Admins.reset_password_request(context.admin.email)
    assert res == {:error, "Password Reset not allowed"}
  end

  test "invalid email error works" do
    res = Admins.reset_password_request("gibberish@gibberish.com")
    assert res == {:error, "Email address not found"}
  end

  test "reset password does not reset when not matched" do
    res = Admins.reset_password("", "match1", "match2")
    assert res == {:error, "Password does not match confirmation"}
  end

  test "reset pw works", context do
    result = Admins.reset_password_request(context.admin.email)
    assert %Bamboo.Email{assigns: %{layout: :admin, token: token}} = result
    assert token
  end

  describe "bounce_admin_email/2" do
    test "inserts admin email when bounce status is true", ~M[admin] do
      bounce_status = true
      admin_email = admin.email

      Admins.do_bounce_admin_email(ClientSchema.new("dasmen", admin_email), bounce_status)

      bounced_email =
        from(
          bounce in Bounce,
          where: bounce.target == ^admin_email
        )
        |> Repo.one()
        |> Map.get(:target)

      assert admin.email == bounced_email
    end

    test "deletes admin email when bounce status is false", ~M[admin] do
      bounce_status = false
      admin_email = admin.email
      client = AppCount.Public.get_client_by_schema("dasmen")

      Repo.insert(%Bounce{target: admin_email}, prefix: client.client_schema)

      # When
      Admins.do_bounce_admin_email(ClientSchema.new("dasmen", admin_email), bounce_status)

      bounced_email =
        from(
          bounce in Bounce,
          where: bounce.target == ^admin_email
        )
        |> Repo.one(prefix: client.client_schema)

      assert is_nil(bounced_email)
    end

    test "handles the edge case with two identical emails in bounce when bounce status is false",
         ~M[admin] do
      bounce_status = false
      admin_email = admin.email

      client = AppCount.Public.get_client_by_schema("dasmen")

      Repo.insert(%Bounce{target: admin_email}, prefix: client.client_schema)
      Repo.insert(%Bounce{target: admin_email}, prefix: client.client_schema)

      found_entries =
        from(
          bounce in Bounce,
          where: bounce.target == ^admin_email
        )
        |> Repo.all(prefix: client.client_schema)

      assert length(found_entries) == 2

      # When
      Admins.do_bounce_admin_email(ClientSchema.new("dasmen", admin_email), bounce_status)

      bounced_email =
        from(
          bounce in Bounce,
          where: bounce.target == ^admin_email
        )
        |> Repo.one(prefix: client.client_schema)

      assert is_nil(bounced_email)
    end
  end
end
