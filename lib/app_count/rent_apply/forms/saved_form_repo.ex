defmodule AppCount.RentApply.Forms.SavedFormRepo do
  alias AppCount.Repo
  alias AppCount.RentApply.Forms
  alias AppCount.RentApply.Forms.SavedForm
  alias AppCount.RentApply.Forms.Cryptor
  require Logger

  def count() do
    Repo.count(SavedForm)
  end

  def generate_pin() do
    generate_pin_fn = Application.get_env(:app_count, :generate_pin_fn, &Cryptor.generate_pin/0)
    generate_pin_fn.()
  end

  def errors_map(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def errors_list(changeset) do
    changeset
    |> errors_map()
    |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
  end

  def errors(changeset) do
    changeset
    |> errors_list()
    |> Enum.join("; ")
  end

  def create_saved_form(
        applicant_email,
        property_id,
        %{} = cleartext_form,
        %{} = attrs,
        applicant_pin
      ) do
    crypted_form = Cryptor.encrypt(cleartext_form, applicant_pin)

    result =
      Forms.insert_saved_form(
        {applicant_email, ""},
        property_id,
        cleartext_form,
        attrs,
        crypted_form
      )

    case result do
      {:ok, saved_form} ->
        {:ok, saved_form}

      {:error, changeset} ->
        Logger.error("SavedForm did not save.  ${errors(message)}")
        {:error, changeset}
    end
  end
end
