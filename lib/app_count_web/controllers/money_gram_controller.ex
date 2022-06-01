defmodule AppCountWeb.MoneyGramController do
  use AppCountWeb, :controller
  alias AppCount.Ledgers.Utils.Payments

  def create(conn, %{xml: xml}) do
    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, Payments.process_moneygram_payment(xml))
  end
end
