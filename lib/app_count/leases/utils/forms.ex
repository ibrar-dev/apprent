defmodule AppCount.Leases.Utils.Forms do
  alias AppCount.Repo
  alias AppCount.Leases
  alias AppCount.Leases.Lease
  alias AppCount.Leases.Form
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def create_form(params) do
    %Form{}
    |> Form.changeset(params)
    |> Repo.insert()
  end

  def unlock_form(id) do
    Repo.get(Form, id)
    |> Form.changeset(%{locked: false})
    |> Repo.update()
  end

  def update_form(id, params) do
    case Repo.get(Form, id) do
      %{locked: false} = f -> do_update(f, params)
      %{locked: true} -> {:error, :locked}
      e -> e
    end
  end

  def get_application_lease_form(application_id) do
    from(
      l in Form,
      join: a in assoc(l, :application),
      join: p in assoc(a, :persons),
      where: l.application_id == ^application_id,
      select: map(l, ^AppCount.EctoExtensions.schema_fields(Form)),
      select_merge: %{
        approval_params: type(a.approval_params, :map),
        persons: jsonize(p, [:id, :status, :full_name])
      },
      group_by: [l.id, a.id]
    )
    |> Repo.one()
    |> case do
      nil ->
        create_form(%{application_id: application_id})
        get_application_lease_form(application_id)

      l ->
        l
    end
  end

  def create_form_from_bluemoon(%{
        "lease_id" => lease_id,
        "bluemoon_id" => b_id,
        "signature_id" => sig_id
      }) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      where: l.id == ^lease_id,
      select: %{
        property_id: u.property_id
      }
    )
    |> Repo.one()
    |> AppCount.Leases.Utils.BlueMoon.property_credentials()
    |> BlueMoon.get_lease_data(b_id)
    |> case do
      {:ok, _} -> do_create_form_from_bluemoon(lease_id, b_id, sig_id)
      _ -> {:error, "No such form"}
    end
  end

  def create_from_bluemoon(_params) do
    {:error, "You are missing one or more of: Lease, Bluemoon ID, or Signature"}
  end

  defp update_application_params(nil, _params), do: nil

  defp update_application_params(id, params) do
    app = Repo.get(AppCount.RentApply.RentApplication, id)

    approval_params =
      app.approval_params
      |> Map.from_struct()
      |> Map.merge(params)

    app
    |> AppCount.RentApply.RentApplication.changeset(%{approval_params: approval_params})
    |> Repo.update()
  end

  defp do_update(%{form_id: _} = form, params) do
    update_application_params(params["application_id"], %{deposit_amount: params["deposit_value"]})

    form
    |> Form.changeset(params)
    |> Repo.update()
  end

  defp do_create_form_from_bluemoon(lease_id, form_id, signature_id) do
    # TODO:SCHEMA remove dasmen
    lease_id
    |> Leases.update_lease(
      ClientSchema.new("dasmen", %{
        bluemoon_lease_id: form_id,
        bluemoon_signature_id: signature_id
      })
    )
    |> case do
      {:ok, lease} ->
        AppCount.Core.Tasker.start(fn -> save_form_pdf(lease_id, signature_id) end)
        {:ok, lease}

      e ->
        e
    end
  end

  def save_form_pdf(lease_id, signature_id) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      where: l.id == ^lease_id,
      select: %{
        property_id: u.property_id
      }
    )
    |> Repo.one()
    |> AppCount.Leases.Utils.BlueMoon.property_credentials()
    |> BlueMoon.get_signature_pdf(signature_id)
    |> case do
      {:ok, base64_pdf} ->
        uuid =
          Base.decode64!(base64_pdf)
          |> AppCount.Data.binary_to_upload("lease.pdf", "application/pdf")

        doc = %{"uuid" => uuid}
        Leases.update_lease(lease_id, %{document: doc})

      _ ->
        nil
    end
  end
end
