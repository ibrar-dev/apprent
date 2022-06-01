defmodule AppCountWeb.API.SavedFormView do
  use AppCountWeb, :view
  alias AppCountWeb.API.SavedFormView

  def render("index.json", %{saved_forms: saved_forms}) do
    %{data: render_many(saved_forms, SavedFormView, "saved_form.json")}
  end

  def render("show.json", %{saved_form: saved_form}) do
    render_one(saved_form, SavedFormView, "saved_form.json")
  end

  def render("saved_form.json", %{saved_form: saved_form}) do
    %{id: saved_form.id, email: saved_form.email, form: saved_form.form}
  end
end
