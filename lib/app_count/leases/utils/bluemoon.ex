defmodule AppCount.Leases.Utils.BlueMoon do
  alias AppCount.Repo
  alias AppCount.RentApply
  alias AppCount.Leases
  alias AppCount.Leases.Form
  alias AppCount.Leases.Lease
  alias AppCount.Properties.Processor
  alias BlueMoon.Requests.RequestSignature
  alias BlueMoon.Credentials
  import Ecto.Query
  import AppCount.EctoExtensions
  require Logger

  def request_bluemoon_signature(credentials, params) do
    %{
      admin: admin,
      property_phone: phone,
      bluemoon_id: bluemoon_id,
      residents: residents,
      form: form
    } = params

    %{name: admin_name, email: admin_email} = admin

    %RequestSignature.Parameters{
      owner: %RequestSignature.Person{
        name: admin_name,
        email: admin_email,
        phone: phone
      },
      residents: residents,
      lease_id: bluemoon_id,
      credentials: credentials
    }
    |> BlueMoon.request_esignature()
    |> case do
      {:ok, sig_id} ->
        Leases.update_form(form.id, %{
          signature_id: sig_id,
          locked: true,
          signed: false,
          admin: admin_name
        })

      e ->
        e
    end
  end

  def get_bluemoon_url(form_id) do
    {form_id, keys} =
      from(
        l in Form,
        join: a in assoc(l, :application),
        join: p in assoc(a, :property),
        join: pr in assoc(p, :processors),
        where: l.id == ^form_id,
        where: pr.type == "lease",
        select: {l.form_id, pr.keys}
      )
      |> Repo.one()

    prop_id = Enum.at(keys, 3)

    "https://bluemoonforms.com/products/forms_online/enterprise/launch/index.php?propid=#{prop_id}&record=#{
      form_id
    }&url=/products/forms_online/lease_db/editor/index.php%3Fmode%3Dedit%26url%3D%252Fproducts%252Fforms_online%252Flease_db%252Fedit%252Findex.php"
  end

  def get_signature_status(%Lease{} = lease) do
    credentials =
      from(
        u in AppCount.Properties.Unit,
        where: u.id == ^lease.unit_id,
        select: %{
          property_id: u.property_id
        }
      )
      |> Repo.one()
      |> property_credentials()

    with {:ok, lease_xml} <-
           BlueMoon.get_lease_data(credentials, lease.pending_bluemoon_lease_id),
         {:ok, status} <-
           BlueMoon.get_signature_status(credentials, lease.pending_bluemoon_signature_id) do
      lease_params = BlueMoon.Data.Params.to_params(lease_xml)

      num_signed =
        Enum.filter(status, fn %{date_signed: d} -> d != "" end)
        |> length

      if num_signed == length(lease_params.residents),
        do: create_from_bluemoon(credentials, lease, lease_params, lease.renewal_admin)
    else
      e -> e
    end
  end

  def get_signature_status(form_id) do
    {signature_id, property_id, _} = lease_signature(form_id)

    property_credentials(%{property_id: property_id})
    |> BlueMoon.get_signature_status(signature_id)
    |> case do
      {:ok, status} ->
        form = Repo.get(Form, form_id)
        new_status = Enum.into(status, %{}, fn %{name: n, date_signed: d} -> {n, d} end)

        form
        |> Form.changeset(%{status: Map.merge(form.status, new_status)})
        |> Repo.update()
        |> update_application_status

      e ->
        e
    end
  end

  defp create_from_bluemoon(credentials, lease, lease_params, admin) do
    with {:ok, "true"} <-
           BlueMoon.execute_lease(credentials, lease.pending_bluemoon_signature_id, admin),
         {:ok, changes} <- Leases.new_lease_from_bluemoon_xml(lease, lease_params) do
      Leases.save_lease_pdf(changes.lease.id)
    else
      {:error, "Lease document has already been executed."} ->
        case Leases.new_lease_from_bluemoon_xml(lease, lease_params) do
          {:ok, changes} -> Leases.save_lease_pdf(changes.lease.id)
          e -> e
        end

      e ->
        Logger.error("BlueMoon execution error")
        Logger.error(inspect(e))
        e
    end
  end

  def signature_pdf(form_id) do
    {signature_id, property_id, _} = lease_signature(form_id)

    property_credentials(%{property_id: property_id})
    |> BlueMoon.get_signature_pdf(signature_id)
  end

  def execute_lease(form_id) do
    {signature_id, property_id, admin} = lease_signature(form_id)

    property_credentials(%{property_id: property_id})
    |> BlueMoon.execute_lease(signature_id, admin)
  end

  def finalize(form_id) do
    execute_lease(form_id)
    save_form_pdf(form_id)

    Repo.get(Form, form_id)
    |> Form.changeset(%{signed: true})
    |> Repo.update()
  end

  def save_form_pdf(form_id) do
    case signature_pdf(form_id) do
      {:ok, base64_pdf} ->
        uuid =
          Base.decode64!(base64_pdf)
          |> AppCount.Data.binary_to_upload("lease.pdf", "application/pdf")

        doc = %{"uuid" => uuid}

        Repo.get(Form, form_id)
        |> Form.changeset(%{document: doc})
        |> Repo.update()

      _ ->
        nil
    end
  end

  def sync_bluemoon_lease(admin, form_id) do
    params =
      from(
        f in Form,
        join: l in assoc(f, :lease),
        join: t in assoc(l, :tenants),
        join: u in assoc(l, :unit),
        where: f.id == ^form_id,
        select: %{
          lease_id: f.lease_id,
          bluemoon_id: f.form_id,
          property_id: u.property_id,
          tenants: array(fragment("? || ' ' || ?", t.first_name, t.last_name))
        },
        group_by: [f.id, u.id]
      )
      |> Repo.one()

    credentials = property_credentials(%{property_id: params.property_id})

    lease_params =
      params.tenants
      |> Enum.with_index(1)
      |> Enum.map(fn {name, index} ->
        {"RESIDENT-#{index}", name}
      end)

    edit_params = %BlueMoon.Requests.EditLease.Parameters{
      lease_id: params.bluemoon_id,
      lease_params: lease_params,
      custom_params: []
    }

    case BlueMoon.edit_lease(credentials, edit_params) do
      {:ok, "true"} ->
        send_signature_request_for_lease(admin, params.lease_id)
        {:ok, true}

      e ->
        Logger.error(e)
        {:error, "failed to sync"}
    end
  end

  def send_signature_request_for_lease(admin, lease_id) do
    from(
      f in Form,
      join: l in assoc(f, :lease),
      join: t in assoc(l, :tenants),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      where: f.lease_id == ^lease_id,
      select: %{
        property_id: u.property_id,
        bluemoon_id: f.form_id,
        form_id: f.id,
        phone: p.phone,
        tenants: jsonize(t, [:id, :first_name, :last_name, :phone, :email])
      },
      group_by: [u.id, f.id, p.id]
    )
    |> Repo.one()
    |> case do
      nil ->
        nil

      result ->
        %RequestSignature.Parameters{
          owner: %RequestSignature.Person{
            name: admin.name,
            email: admin.email,
            phone: result.phone
          },
          residents:
            Enum.map(
              result.tenants,
              fn t ->
                %RequestSignature.Person{
                  name: "#{t["first_name"]} #{t["last_name"]}",
                  email: t["email"],
                  phone: t["phone"]
                }
              end
            ),
          lease_id: result.bluemoon_id,
          credentials: property_credentials(%{property_id: result.property_id})
        }
        |> BlueMoon.request_esignature()
        |> case do
          {:ok, sig_id} ->
            Repo.get(Leases.Form, result.form_id)
            |> Leases.Form.changeset(%{signature_id: sig_id, locked: true, admin: admin.name})
            |> Repo.update()

          e ->
            e
        end
    end
  end

  def get_bluemoon_lease(lease_id, form_id) do
    property_id =
      from(l in Lease, where: l.id == ^lease_id, join: u in assoc(l, :unit), select: u.property_id)
      |> Repo.one()

    property_credentials(%{property_id: property_id})
    |> BlueMoon.get_lease_data(form_id)
  end

  def property_credentials(%{property_id: property_id}) do
    from(
      p in Processor,
      where: p.property_id == ^property_id and p.name == "BlueMoon",
      select: p
    )
    |> Repo.one()
    |> case do
      nil ->
        raise "No processor found for this property"

      %{keys: [serial, user, password, property_id]} ->
        %Credentials{serial: serial, user: user, password: password, property_id: property_id}

      %{keys: [serial, user, password]} ->
        %Credentials{serial: serial, user: user, password: password}
    end
  end

  defp update_application_status({:ok, %{application_id: application_id} = form})
       when not is_nil(application_id) do
    num_signed =
      Enum.filter(form.status, fn {_, v} -> v != "" end)
      |> length

    from(
      r in RentApply.RentApplication,
      join: p in assoc(r, :persons),
      where: r.id == ^application_id,
      where: r.status == "lease_sent",
      where: p.status == "Lease Holder",
      select: {count(p.id), r.id},
      group_by: r.id
    )
    |> Repo.one()
    |> case do
      nil ->
        update_lease_status(form)

      {num_persons, app_id} ->
        if num_persons == num_signed do
          AppCount.Core.Tasker.start(fn ->
            finalize(form.id)
            RentApply.application_signed(app_id)
          end)
        end
    end
  end

  defp update_application_status(e), do: e

  defp update_lease_status(%{lease_id: lease_id} = form) when not is_nil(lease_id) do
    num_signed =
      Enum.filter(form.status, fn {_, v} -> v != "" end)
      |> length

    from(
      l in Lease,
      join: t in assoc(l, :tenants),
      where: l.id == ^lease_id,
      select: count(t.id),
      group_by: l.id
    )
    |> Repo.one()
    |> case do
      nil ->
        nil

      num_persons ->
        if num_persons == num_signed do
          AppCount.Core.Tasker.start(fn -> finalize(form.id) end)
        end
    end
  end

  defp update_lease_status(_), do: nil

  defp lease_signature(form_id) do
    from(
      f in Form,
      left_join: a in assoc(f, :application),
      left_join: l in assoc(f, :lease),
      left_join: u in assoc(l, :unit),
      where: f.id == ^form_id,
      select: {f.signature_id, coalesce(a.property_id, u.property_id), f.admin}
    )
    |> Repo.one()
  end
end
