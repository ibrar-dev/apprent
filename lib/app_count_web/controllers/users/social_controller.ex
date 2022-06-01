defmodule AppCountWeb.Users.SocialController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCount.Properties
  alias AppCount.Socials
  alias AppCount.Rewards
  alias AppCount.Core.ClientSchema

  def index(conn, _params) do
    post = Ecto.Changeset.change(%Socials.Post{})
    property_id = Accounts.get_property_id(conn.assigns.user.uuid)
    property_info = Properties.public_property_data(property_id)
    property_package = Properties.list_resident_packages(915_501)
    user_payments = Accounts.list_payments(915_501, 5)
    balances = Accounts.user_balance(conn.assigns.user.id)

    balance =
      cond do
        Kernel.length(balances) >= 1 ->
          Enum.reduce(Enum.map(balances, fn x -> x.balance end), fn x, acc ->
            Decimal.add(x, acc)
          end)

        true ->
          0
      end

    due_date =
      cond do
        0 -> 0
        true -> List.first(balances).date
      end

    user_orders =
      Accounts.get_orders(ClientSchema.new(conn.assigns.client_schema, conn.assigns.user.id))

    user_balance = %{
      balance: balance,
      due_date: due_date
    }

    events = Properties.list_resident_events(property_id)
    posts = Socials.get_posts(conn.assigns.user.id)
    user_posts = Socials.get_user_posts(conn.assigns.user.id)
    likes = Socials.get_likes(conn.assigns.user.id)
    {_history, points} = Rewards.tenant_history(conn.assigns.user.id)

    rewards =
      Rewards.list_rewards()
      |> Enum.filter(&(&1.promote && &1.points > points))
      |> Enum.take_random(6)

    render(conn, "index.html",
      property_info: property_info,
      property_package: property_package,
      user_balance: user_balance,
      user_payments: user_payments,
      user_orders: user_orders,
      events: events,
      post: post,
      posts: posts,
      likes: likes,
      postIndex: 0,
      points: points,
      rewards: rewards,
      user_posts: user_posts
    )
  end

  def create(conn, %{"report" => params}) do
    Socials.create_report(params)
    json(conn, %{})
  end

  def create(conn, %{"block" => params}) do
    Socials.create_block(params)
    json(conn, %{})
  end

  def create(conn, params) do
    Socials.create_post(
      %{"tenant_id" => conn.assigns.user.id, "property_id" => conn.assigns.user.property.id},
      params
    )

    conn
    |> redirect(to: Routes.user_social_path(conn, :index))
  end

  def update(conn, %{"params" => params}) do
    if params["like_id"] == "" do
      Socials.create_like(params)
    else
      Socials.delete_like(%{post_id: params["post_id"], tenant_id: params["tenant_id"]})
    end

    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Socials.delete_post(id)
    json(conn, %{})
  end
end
