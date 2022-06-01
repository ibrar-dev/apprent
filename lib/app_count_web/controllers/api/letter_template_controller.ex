defmodule AppCountWeb.API.LetterTemplateController do
  use AppCountWeb, :controller
  alias AppCount.Properties
  alias AppCount.Properties.Utils.LetterTemplates
  alias AppCountWeb.LetterPreviewer

  authorize(["Regional", "Accountant"],
    index: ["Agent", "Admin"],
    show: ["Agent", "Admin"],
    create: ["Admin"]
  )

  def index(conn, %{"property_id" => property_id}) do
    json(conn, Properties.get_letter_templates(property_id))
  end

  def create(conn, %{"letter_template" => params}) do
    Properties.create_letter_template(params)
    |> handle_error(conn)
  end

  def create(conn, %{"html" => html, "property_id" => property_id}) do
    result =
      LetterTemplates.random_letter_contents_with_codes(html, %{property_id: property_id})
      |> LetterPreviewer.generate_binary()

    case result do
      {:ok, binary} ->
        json(conn, %{pdf: Base.encode64(binary)})

      _ ->
        json(conn, %{error: "ERROR GENERATING PREVIEW"})
    end
  end

  def create(conn, %{"generate" => params}) do
    generate_binary_fn = &AppCountWeb.LetterPreviewer.generate_binary/1

    AppCount.Properties.Utils.LetterTemplates.generate_letters(
      conn.assigns.admin,
      params,
      generate_binary_fn
    )

    json(conn, %{})
  end

  def show(conn, %{"id" => template_id, "tenant_id" => tenant_id}) do
    result =
      LetterTemplates.letter_contents(template_id, tenant_id)
      |> LetterPreviewer.generate_binary()

    case result do
      {:ok, binary} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> send_resp(200, binary)

      _ ->
        redirect(conn, Routes.static_path(conn, "/images/error.pdf"))
    end
  end

  def show(conn, %{"id" => template_id}) do
    result =
      LetterTemplates.random_letter_contents(template_id)
      |> LetterPreviewer.generate_binary()

    case result do
      {:ok, binary} ->
        data =
          binary
          |> :erlang.term_to_binary()
          |> Base.encode64()

        json(conn, %{pdf: data})

      _ ->
        json(conn, %{error: "ERROR GENERATING PREVIEW"})
    end
  end

  def update(conn, %{"id" => id, "letter_template" => params}) do
    case Properties.update_letter_template(id, params) do
      {:ok, _} ->
        json(conn, %{})

      {:error, _} ->
        json(conn, %{})
    end
  end

  def delete(conn, %{"id" => id}) do
    Properties.delete_letter_template(id)
    json(conn, %{})
  end
end
