defmodule AppCountWeb.InputHelpers do
  use Phoenix.HTML

  @moduledoc """
  Fancy-pants bootstrap form helpers for forms.

  Taken from:
  http://blog.plataformatec.com.br/2016/09/dynamic-forms-with-phoenix/
  """

  @doc """
  Generate a Bootstrap form field

  Options:
  + label - label to be displayed (defaults to nil)
  + readonly - true/false (defaults to false)
  """
  def input(form, field, options \\ []) do
    type = Phoenix.HTML.Form.input_type(form, field)

    wrapper_opts = [class: "form-group #{state_class(form, field)}"]
    label_opts = [class: "control-label"]
    input_opts = [class: "form-control"]

    validations = Phoenix.HTML.Form.input_validations(form, field)
    input_opts = Keyword.merge(validations, input_opts)

    form_label = options[:label] || humanize(field)
    readonly = options[:readonly] || false

    input_opts = Keyword.merge(input_opts, readonly: readonly)

    content_tag :div, wrapper_opts do
      label = label(form, field, form_label, label_opts)
      input = apply(Phoenix.HTML.Form, type, [form, field, input_opts])
      error = AppCountWeb.ErrorHelpers.error_tag(form, field) || ""
      [label, input, error]
    end
  end

  defp state_class(form, field) do
    cond do
      # Form not yet submitted:
      !form.source.action ->
        ""

      # Form has errors
      form.errors[field] ->
        "has-error"

      # Form is good
      true ->
        "has-success"
    end
  end
end
