defmodule Payscape.Authentication do
  def auth_header(%{keys: [cert, term_id, _]}) do
    "Basic #{Base.encode64("#{cert}:#{term_id}")}"
  end
end
