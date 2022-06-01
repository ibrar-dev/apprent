defmodule AppCountWeb.API.RewardsAnalyticsController do
  use AppCountWeb, :controller

  def index(conn, %{"infoBox" => _, "properties" => comma_sep_numbers})
      when is_binary(comma_sep_numbers) do
    rewards_boundary = rewards_boundary(conn)

    result =
      comma_sep_numbers
      |> to_integers()
      |> rewards_boundary.reward_analytics()

    json(conn, result)
  end
end
