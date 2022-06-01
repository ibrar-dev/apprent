defmodule AppCountWeb.Users.RewardController do
  use AppCountWeb.Users, :controller
  alias AppCount.Repo
  alias AppCount.Rewards
  alias AppCount.Rewards.Reward
  import Ecto.Query

  def print_number(number, total, list) when number <= total do
    new_list =
      case number do
        n when n <= total -> list ++ [number]
        _ -> list
      end

    print_number(number + 1, total, new_list)
  end

  def print_number(number, total, list) when number > total, do: list

  def index(conn, params) do
    {history, points} = Rewards.tenant_history(conn.assigns.user.id)

    page =
      Reward
      |> select([p], map(p, [:id, :name, :icon, :points, :price, :url, :promote]))
      |> Repo.paginate(params)

    #             |> Enum.filter(& &1.promote && &1.points > points)

    link_array = print_number(1, page.total_pages, [])

    eligible =
      Rewards.list_rewards()
      |> Enum.filter(&(&1.points <= points))

    render(conn, "index.html",
      rewards: page.entries,
      p_number: page.page_number,
      total_page: page.total_pages,
      points: points,
      history: history,
      eligible: eligible,
      link_array: link_array
    )
  end

  def create(conn, %{"reward_ids" => reward_ids}) do
    Rewards.purchase_rewards(conn.assigns.user.id, reward_ids)
    json(conn, %{})
  end

  def create(conn, %{"reward_id" => reward_id}) do
    case Rewards.purchase_reward(conn.assigns.user.id, reward_id) do
      {:ok, _} ->
        json(conn, %{})

      {:error, e} ->
        conn
        |> put_status(422)
        |> json(%{error: e})
    end
  end
end
