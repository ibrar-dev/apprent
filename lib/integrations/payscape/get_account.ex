defmodule Payscape.GetAccount do
  import XmlBuilder
  alias Payscape.Request
  require Logger

  def get(processor) do
    req = request(processor)

    Request.request(req, processor)
    |> case do
      {:ok, body} -> File.write("resp.xml", body)
      e -> Logger.error(e)
    end
  end

  def get_accounts(processor) do
    req = accounts_request(processor)

    Request.request(req, processor)
    |> case do
      {:ok, body} -> File.write("resp.xml", body)
      e -> Logger.error(e)
    end
  end

  def request(%{keys: [cert, term, num]}) do
    document([
      doctype("Request.dtd", system: ""),
      element(
        :XMLRequest,
        [
          element(:certStr, cert),
          element(:termid, term),
          element(:class, "partner"),
          element(:XMLTrans, [
            element(:transType, 13),
            element(:accountNum, num)
          ])
        ]
      )
    ])
    |> generate()
  end

  def accounts_request(%{keys: [cert, term, _num]}) do
    document([
      doctype("Request.dtd", system: ""),
      element(
        :XMLRequest,
        [
          element(:certStr, cert),
          element(:termid, term),
          element(:class, "partner"),
          element(:XMLTrans, [
            element(:transType, 27),
            element(:beginDate, "12-20-2018"),
            element(:endDate, "12-30-2018")
          ])
        ]
      )
    ])
    |> generate()
  end
end
