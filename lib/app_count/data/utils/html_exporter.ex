defmodule AppCount.Data.Utils.HtmlExporter do
  # FIX_DEPS move to WEB
  def generate_pdf(binary) do
    Phoenix.View.render_to_string(AppCountWeb.Data.View, "index.html", %{content: binary})
    |> PdfGenerator.generate_binary(
      shell_params: [
        "--footer-right",
        get_generated_time(),
        "--footer-center",
        "[page]/[toPage]",
        "--footer-font-size",
        "8"
      ]
    )
    |> convert_to_base64()
  end

  defp convert_to_base64({:ok, binary}) do
    {:ok, Base.encode64(binary)}
    #    file_path = "/tmp/pdfs/output.pdf"
    #    File.write(file_path, binary)
    #    file_path
  end

  defp convert_to_base64(e), do: e

  defp get_generated_time(),
    do:
      AppCount.current_time()
      |> Timex.format!("%b %d %y, %I:%M%p", :strftime)
      |> Kernel.<>(" EST")
end
