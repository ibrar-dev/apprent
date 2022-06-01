defmodule AppCount.Properties.Utils.LetterTemplates do
  import Ecto.Query
  alias AppCount.Properties.LetterTemplate
  alias AppCount.Repo
  alias AppCount.Data
  alias AppCount.ShortCodes
  alias AppCount.Tenants.Tenancy
  require Logger
  alias AppCount.Core.ClientSchema

  def create_letter_template(params) do
    %LetterTemplate{}
    |> LetterTemplate.changeset(params)
    |> Repo.insert()
  end

  def update_letter_template(id, params) do
    Repo.get(LetterTemplate, id)
    |> LetterTemplate.changeset(params)
    |> Repo.update()
  end

  def delete_letter_template(id) do
    Repo.get(LetterTemplate, id)
    |> Repo.delete()
  end

  def get_letter_templates(property_id) do
    from(
      l in LetterTemplate,
      where: l.property_id == ^property_id,
      select: %{
        id: l.id,
        name: l.name,
        body: l.body,
        property_id: l.property_id
      }
    )
    |> Repo.all()
  end

  def show_letter_template(id) do
    Repo.get(LetterTemplate, id)
  end

  def random_letter_contents(template_id) do
    %{property_id: property_id} = Repo.get(LetterTemplate, template_id)
    random_tenant_id = random_tenant_id(property_id)
    _html = letter_contents(template_id, random_tenant_id)
  end

  def random_letter_contents_with_codes(html, %{property_id: property_id}) do
    tenant_id = random_tenant_id(property_id)
    _html = ShortCodes.parse_short_codes(html, %{tenant_id: tenant_id})
  end

  def letter_contents(template_id, tenant_id) do
    template = Repo.get(LetterTemplate, template_id)
    ShortCodes.parse_short_codes(template.body, %{tenant_id: tenant_id})
  end

  def generate_letters(
        admin,
        %{
          "template_id" => id,
          "tenant_ids" => tenant_ids,
          "visible" => visible,
          "notify" => notify
        },
        generate_binary_fn
      )
      when is_function(generate_binary_fn, 1) do
    letter = Repo.get(LetterTemplate, id)

    AppCount.Core.Tasker.start(fn ->
      tenant_ids
      |> Enum.map(fn t ->
        letter_contents(id, t)
        |> generate_binary_fn.()
        |> save(letter, t, visible, notify)
      end)
      |> AppCount.Data.concatenate_pdfs()
      |> email_admin(admin)
    end)

    AppCount.Admins.create_alert(
      %{
        sender: "Letters",
        note:
          "Your letters are being generated and will be emailed to you when ready. \nPlease also note that the letters will automatically be uploaded to the residents account.",
        admin_id: admin.id,
        flag: 3
      },
      :nonsave
    )
  end

  def convert_to_base64({:error, e}), do: Logger.error(e)

  def convert_to_base64(binary) do
    binary
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  defp save({:ok, binary}, letter, tenant_id, visible, notify) do
    AppCount.Core.Tasker.start(fn ->
      save_to_aws(binary, letter, tenant_id, visible)
      |> maybe_notify(letter, notify)
    end)

    binary
  end

  defp save_to_aws(binary, letter, tenant_id, visible) do
    date_stamp = Timex.format!(AppCount.current_time(), "{M}_{D}_{YYYY}")
    filename = "#{tenant_id}_#{date_stamp}_#{letter.name}.pdf"
    uuid = Data.binary_to_upload(binary, filename, "application/pdf")
    save_to_resident(tenant_id, uuid, filename, letter, visible)
  end

  defp save_to_resident(tenant_id, uuid, filename, letter, visible) do
    tenancy = tenant_id_from_tenancy(tenant_id)

    %{
      document: %{
        "uuid" => uuid
      },
      name: filename,
      tenant_id: tenancy.tenant_id,
      type: letter.name,
      visible: visible
    }
    |> AppCount.Properties.create_document()
  end

  defp tenant_id_from_tenancy(tenancy_id) when is_binary(tenancy_id),
    do: tenant_id_from_tenancy(String.to_integer(tenancy_id))

  defp tenant_id_from_tenancy(tenancy_id) do
    Repo.get(Tenancy, tenancy_id)
  end

  defp maybe_notify({:error, e}, _, _), do: Logger.error(e)

  defp maybe_notify({:ok, doc}, letter, notify) do
    cond do
      notify -> notify(doc, letter)
      true -> nil
    end
  end

  defp notify(%{tenant_id: tenant_id} = _doc, letter) do
    AppCount.Core.Tasker.start(fn ->
      tenant = Repo.get(AppCount.Tenants.Tenant, tenant_id)
      property = AppCount.Properties.get_property(ClientSchema.new("dasmen", letter.property_id))

      case tenant.email do
        nil ->
          nil

        _ ->
          AppCountCom.Tenants.new_resident_letter(
            %{property: property, tenant: tenant},
            letter.name
          )
      end
    end)
  end

  def email_admin(binary, admin) do
    path = "/tmp/pdfs/#{UUID.uuid4()}"
    filename = "#{AppCount.current_date()}_generated_letters.pdf"
    File.mkdir_p(path)
    file = "#{path}/#{filename}"
    File.write(file, binary)

    uuid = Data.binary_to_upload(binary, filename, "application/pdf")

    File.rm_rf!(path)

    AppCount.Admins.create_alert(%{
      attachment: %{
        "uuid" => uuid
      },
      sender: "Letters",
      note: "Your letters have been generated and can be now be downloaded.",
      admin_id: admin.id,
      flag: 3
    })
  end

  defp random_tenant_id(property_id) do
    occ_sub =
      from(
        o in AppCount.Properties.Occupancy,
        join: l in assoc(o, :lease),
        join: u in assoc(l, :unit),
        where: u.property_id == ^property_id,
        select: %{
          id: o.id,
          tenant_id: o.tenant_id
        }
      )

    from(
      t in AppCount.Tenants.Tenant,
      join: o in subquery(occ_sub),
      on: o.tenant_id == t.id,
      order_by: fragment("RANDOM()"),
      limit: 1,
      select: t.id
    )
    |> Repo.one()
  end
end
