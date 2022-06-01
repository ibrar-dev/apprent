defmodule AppCount.UploadServerTest do
  use AppCount.Case
  alias AppCount.UploadServer
  @moduletag :upload_server

  %Plug.Upload{
    content_type: "application/pdf",
    filename: "Sample1.pdf",
    path: Path.expand("../resources/Sample1.pdf", __DIR__)
  }

  test "upload server works with jumbled slices" do
    sample_file_data =
      Path.expand("../resources/Sample1.pdf", __DIR__)
      |> File.read!()

    uuid = UploadServer.initialize_upload(4, "whatever.pdf", "application/pdf")

    Enum.map(
      [2, 1, 4, 3],
      fn num ->
        %Plug.Upload{
          content_type: "application/pdf",
          filename: "#{uuid}.#{num}.pdf",
          path: Path.expand("../resources/Sample1Slices/slice-#{num}.pdf", __DIR__)
        }
      end
    )
    |> Enum.each(&UploadServer.push_piece/1)

    %UploadServer.Upload{chunks: [data], content_type: ct, filename: f} =
      UploadServer.finish(uuid)

    assert data == sample_file_data
    assert ct == "application/pdf"
    assert f == "whatever.pdf"
    assert UploadServer.finish(uuid) == {:error, "Invalid Session ID"}
  end

  test "error handling" do
    UploadServer.initialize_upload(4, "whatever.pdf", "application/pdf")

    Enum.map(
      [2, 1, 4, 3],
      fn num ->
        %Plug.Upload{
          content_type: "application/pdf",
          filename: "#{UUID.uuid4()}.#{num}.pdf",
          path: Path.expand("../resources/Sample1Slices/slice-#{num}.pdf", __DIR__)
        }
      end
    )
    |> Enum.each(&UploadServer.push_piece/1)

    assert UploadServer.finish(UUID.uuid4()) == {:error, "Invalid Session ID"}
  end
end
