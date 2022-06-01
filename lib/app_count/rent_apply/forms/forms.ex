defmodule AppCount.RentApply.Forms do
  @moduledoc """
  The Forms context.
  """

  import Ecto.Query, warn: false
  alias AppCount.RentApply.Forms.Cryptor
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  alias AppCount.RentApply.Forms.SavedForm
  require Logger

  @doc """
  Gets a single saved_form.

  ## Examples

      iex> get_saved_form!(123)
      %SavedForm{}

      iex> get_saved_form!(456)
      ** (Ecto.NoResultsError)

  """
  def get_saved_form(property_id, email) do
    SavedForm
    |> from(
      where: [
        property_id: ^property_id,
        email: ^email
      ]
    )
    |> Repo.one()
  end

  @spec get_decrypted_form(number, String.t(), String.t()) :: {:error, :bad_auth} | {:ok, map}
  def get_decrypted_form(property_id, email, pin) do
    case get_saved_form(property_id, email) do
      nil -> {:error, :bad_auth}
      %SavedForm{} = form -> decrypt_form(form, pin)
    end
  end

  @spec decrypt_form(%SavedForm{crypted_form: String.t()}, String.t()) ::
          {:ok, %{form: map()}} | {:error, :bad_auth}
  def decrypt_form(%SavedForm{crypted_form: crypt} = form, pin) do
    Cryptor.decrypt(crypt, pin)
    |> Jason.decode()
    |> case do
      {:ok, decoded} ->
        r =
          Map.put(form, :form, decoded)
          |> Map.delete(:crypted_form)

        {:ok, r}

      _ ->
        {:error, :bad_auth}
    end
  end

  def generate_pin() do
    Cryptor.generate_pin()
  end

  @doc """
  Creates a saved_form.

  ## Examples

      iex> create_saved_form(%{field: value})
      {:ok, %SavedForm{}}

      iex> create_saved_form(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_saved_form(property_id, %{} = cleartext_form, %{} = form_data) do
    # generate pin
    pin = generate_pin()
    crypted_form = Cryptor.encrypt(cleartext_form, pin)

    # arrange attrs
    case insert_saved_form(property_id, cleartext_form, form_data, crypted_form) do
      {:ok, saved_form} ->
        email_notify(saved_form, pin)

      {:error, changeset} ->
        Logger.error(
          "SavedForm could not be inserted because #{inspect(Enum.join(changeset.errors))}"
        )
    end
  end

  # The first occupant will be the Lease Holder, so is the applicant.  Only used by the React client
  def insert_saved_form(
        property_id,
        %{
          "occupants" => [
            %{
              "email" => applicant_email,
              "full_name" => applicant_full_name,
              "status" => "Lease Holder"
            }
            | _
          ]
        } = form_attrs,
        %{} = form_data,
        crypted_form
      ) do
    insert_saved_form(
      {applicant_email, applicant_full_name},
      property_id,
      form_attrs,
      form_data,
      crypted_form
    )
  end

  # Passes in the applicant_email and a blank full_name, used by the liveview client
  def insert_saved_form(
        {applicant_email, applicant_full_name},
        property_id,
        %{},
        %{
          "form_summary" => form_summary,
          "language" => language,
          "start_time" => start_time
        },
        crypted_form
      ) do
    saved_form_attrs = %{
      property_id: property_id,
      email: applicant_email,
      name: applicant_full_name,
      crypted_form: crypted_form,
      form_summary: form_summary,
      lang: language,
      start_time: DateTime.from_unix!(start_time)
    }

    # %{saved_form_attrs | crypted_form: "hidden"}
    # |> IO.inspect(
    #   label: "#{List.last(String.split(__ENV__.file, "/"))}:#{__ENV__.line} saved_form_attrs"
    # )

    on_conflict = [
      set: [
        crypted_form: saved_form_attrs.crypted_form,
        form_summary: form_summary,
        name: applicant_full_name,
        lang: language,
        start_time: DateTime.from_unix!(start_time)
      ]
    ]

    %SavedForm{}
    |> SavedForm.changeset(saved_form_attrs)
    |> Repo.insert(on_conflict: on_conflict, conflict_target: [:email, :property_id])
  end

  def email_notify(%SavedForm{} = form, pin) do
    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", form.property_id))

    assigns = [
      property: property,
      pin: pin,
      url: AppCount.namespaced_url("application")
    ]

    AppCountCom.Applications.application_saved(form.email, assigns)

    {:ok, form}
  end

  @doc """
  Updates a saved_form.

  ## Examples

      iex> update_saved_form(saved_form, %{field: new_value})
      {:ok, %SavedForm{}}

      iex> update_saved_form(saved_form, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_saved_form(
        property,
        email,
        pin,
        %{
          "applicant" => %{
            "email" => email
          }
        } = form
      ) do
    attrs = %{email: email, crypted_form: Cryptor.encrypt(form, pin)}

    property
    |> get_saved_form(email)
    |> SavedForm.changeset(attrs)
    |> Repo.update!()
  end

  @doc """
  Deletes a SavedForm.

  ## Examples

      iex> delete_saved_form(saved_form)
      {:ok, %SavedForm{}}

      iex> delete_saved_form(saved_form)
      {:error, %Ecto.Changeset{}}

  """
  def delete_saved_form(%SavedForm{} = saved_form) do
    Repo.delete(saved_form)
  end
end
