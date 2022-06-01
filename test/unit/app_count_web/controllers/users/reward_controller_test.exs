defmodule AppCountWeb.Controllers.Users.RewardControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Rewards
  alias AppCount.Core.ClientSchema
  @moduletag :reward_controller

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    property = insert(:tenancy, tenant: account.tenant).unit.property

    Repo.get_by(Rewards.Type, name: "Signup").id
    |> Rewards.update_type(%{points: 5000})

    Repo.get_by(Rewards.Type, name: "Work Order Created").id
    |> Rewards.update_type(%{points: 250})

    Rewards.create_accomplishment(
      ClientSchema.new("dasmen", %{tenant_id: account.tenant.id, type: "Work Order Created"})
    )

    Rewards.create_accomplishment(
      ClientSchema.new("dasmen", %{tenant_id: account.tenant.id, type: "Signup"})
    )

    reward = insert(:reward, points: 100, name: "Cheap Reward")
    reward2 = insert(:reward, points: 10000, name: "Expensive Reward")
    {:ok, account: account, reward: reward, property: property, reward2: reward2}
  end

  test "user rewards page loads", %{conn: conn, account: account} do
    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/rewards")
      |> html_response(200)

    assert response =~ "Points Activity"
    assert response =~ "Checkout"
    assert response =~ "#{account.property.name}"
  end

  test "user purchase reward works", %{
    conn: conn,
    account: account,
    reward: reward,
    property: property
  } do
    refute Repo.get_by(Rewards.Purchase,
             tenant_id: account.tenant.id,
             reward_id: reward.id,
             property_id: property.id
           )

    response =
      conn
      |> user_request(account)
      |> post("http://residents.example.com/rewards", reward_id: reward.id)
      |> json_response(200)

    assert response == %{}

    assert Repo.get_by(Rewards.Purchase,
             tenant_id: account.tenant.id,
             reward_id: reward.id,
             property_id: property.id
           )
  end

  test "user purchase error handling", %{conn: conn, account: account, reward2: reward2} do
    response =
      conn
      |> user_request(account)
      |> post("http://residents.example.com/rewards", reward_id: reward2.id)
      |> json_response(422)

    assert response == %{"error" => "Not enough points"}
  end
end
