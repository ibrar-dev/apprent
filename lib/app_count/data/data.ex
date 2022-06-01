defmodule AppCount.Data do
  alias AppCount.Data.Utils.Uploads
  alias AppCount.Data.Utils.Files
  alias AppCount.Data.Utils.PDF
  alias AppCount.Data.Utils.HtmlExporter

  def process_upload(u, opts \\ []), do: Uploads.process_upload(u, opts)

  def binary_to_upload(binary, filename, file_type),
    do: Uploads.binary_to_upload(binary, filename, file_type)

  def file_type(binary), do: Files.file_type(binary)

  def concatenate_pdfs(query), do: PDF.concatenate_pdfs(query)

  def export_html(html), do: HtmlExporter.generate_pdf(html)
end
