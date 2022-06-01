defmodule AppCountWeb.LetterPreviewer do
  @moduledoc """
  Calls RentApplications to get data
  and renders it
  This does the data work in AppCount
  And  does the view work in AppCountWeb
  """
  alias AppCount.RentApply.Utils.RentApplications

  def generate_preview(html, %{"property_id" => property_id}) do
    person_id = RentApplications.random_applicant_id(property_id)
    generate_preview(html, %{person_id: person_id})
  end

  def generate_preview(html_template, %{person_id: person_id}) do
    html = RentApplications.letter_contents(html_template, %{person_id: person_id})

    generate_binary(html)
  end

  def generate_binary({:ok, html}) do
    generate_binary(html)
  end

  def generate_binary({:error, html}) do
    generate_binary(html)
  end

  def generate_binary(html) do
    Phoenix.View.render_to_string(
      AppCountWeb.LetterTemplateView,
      "index.html",
      %{html: html}
    )
    |> PdfGenerator.generate_binary()
  end

  def render_check_template(params) do
    Phoenix.View.render_to_string(AppCountWeb.Checks.CheckTemplateView, "index.html", params)
    |> PdfGenerator.generate_binary()
  end
end
