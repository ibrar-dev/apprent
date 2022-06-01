defmodule AppCount.Data.PDFTest do
  use AppCount.DataCase
  import Ecto.Query
  alias AppCount.Data.UploadURL
  alias AppCount.Support.HTTPClient
  @moduletag :pdfs

  setup do
    data1 = File.read!(Path.expand("../../resources/Sample1.pdf", __DIR__))
    data2 = File.read!(Path.expand("../../resources/Sample2.pdf", __DIR__))
    {:ok, [data1: data1, data2: data2]}
  end

  test "works with query", %{data1: data1, data2: data2} do
    insert(:upload, is_public: true, is_loading: false).id
    insert(:upload, is_public: true, is_loading: false)
    HTTPClient.initialize([data1, data2])

    result =
      from(d in UploadURL, select: d.url)
      |> AppCount.Data.concatenate_pdfs()

    HTTPClient.stop()
    assert AppCount.Data.file_type(result) == :pdf
  end

  test "works with binaries", %{data1: data1, data2: data2} do
    assert AppCount.Data.file_type(AppCount.Data.concatenate_pdfs([data1, data2])) == :pdf
  end
end
