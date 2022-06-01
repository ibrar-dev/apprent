defmodule AppCountWeb.API.RentApplyDocumentController do
  use AppCountWeb, :controller

  def show(conn, %{"id" => id}) do
    {filename, data} = AppCount.RentApply.document_data(id)

    conn
    |> put_resp_content_type("application/octet-stream")
    |> put_resp_header("content-disposition", "attachment;filename=#{filename}")
    |> send_resp(200, data)
  end
end
