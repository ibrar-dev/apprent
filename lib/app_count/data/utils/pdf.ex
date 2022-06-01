defmodule AppCount.Data.Utils.PDF do
  alias AppCount.Repo
  alias AppCount.Data
  alias AppCount.Core.HTTPClient

  @spec concatenate_pdfs(%Ecto.Query{} | list) :: binary
  def concatenate_pdfs(input) do
    path = "/tmp/pdfs/#{UUID.uuid4()}"
    File.mkdir_p(path)

    input
    |> to_list()
    |> Task.async_stream(&write_tmp_pdf(&1, path), timeout: 5_000_000)
    |> Enum.map(fn {:ok, v} -> v end)
    |> Enum.filter(&(&1 != :error))
    |> do_concat(path)
  end

  defp to_list(%Ecto.Query{} = query), do: Repo.all(query)
  defp to_list(list) when is_list(list), do: list

  defp write_tmp_pdf("http" <> _ = url, path) do
    case HTTPClient.get(url) do
      {:ok, %{body: body}} -> write_tmp_pdf(body, path)
      _ -> :error
    end
  end

  defp write_tmp_pdf(binary, path) do
    if Data.file_type(binary) == :pdf do
      file_path = "#{path}/#{UUID.uuid4()}.pdf"
      File.write(file_path, binary)
      file_path
    else
      :error
    end
  end

  defp do_concat(files, path) do
    output = "#{path}/out.pdf"

    System.cmd(
      "gs",
      [
        "-q",
        "-sPAPERSIZE=letter",
        "-dNOPAUSE",
        "-dBATCH",
        "-sDEVICE=pdfwrite",
        "-sOutputFile=#{output}"
      ] ++ files
    )

    output = File.read!(output)
    File.rm_rf!(path)
    output
  end
end
