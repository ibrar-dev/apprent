defmodule Google.Token do
  alias Goth.Token

  # Gets the oath token for google cloud, this one is for Language Processing
  def get_ml_token() do
    {:ok, %{token: token}} = Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    token
  end
end
