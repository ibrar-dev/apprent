defmodule AppCount.Messaging.Utils.MailTemplates do
  import Ecto.Query
  alias AppCount.Messaging.MailTemplate
  alias AppCount.Messaging.PropertyTemplate
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def list_templates() do
    from(
      m in MailTemplate,
      select: %{
        id: m.id,
        subject: m.subject,
        body: m.body
      },
      order_by: :inserted_at
    )
    |> Repo.all()
  end

  def list_templates(_) do
    from(
      m in MailTemplate,
      select: %{
        id: m.id,
        subject: m.subject,
        body: m.body,
        history: m.history
      },
      order_by: :inserted_at
    )
    |> Repo.all()
  end

  def list_property_templates(admin) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    template_query =
      from(
        pt in PropertyTemplate,
        where: pt.property_id in ^property_ids,
        select: %{
          id: pt.id,
          property_id: pt.property_id,
          template_id: pt.template_id
        }
      )

    from(
      t in MailTemplate,
      join: pt in subquery(template_query),
      on: t.id == pt.template_id,
      select: %{
        subject: t.subject,
        body: t.body,
        creator: t.creator
      },
      group_by: [t.id]
    )
    |> Repo.all()
  end

  def create_template(params) do
    %MailTemplate{}
    |> MailTemplate.changeset(params)
    |> Repo.insert!()
  end

  def create_property_template(params) do
    %PropertyTemplate{}
    |> PropertyTemplate.changeset(params)
    |> Repo.insert!()
  end

  def create_template(admin, params) do
    new_params = params |> Map.put("creator", admin)

    %MailTemplate{}
    |> MailTemplate.changeset(new_params)
    |> Repo.insert!()
  end

  def edit_template(id, params, admin) do
    Repo.get(MailTemplate, id)
    |> MailTemplate.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, m} -> update_history(m, admin)
      e -> e
    end
  end

  def delete_template(id) do
    Repo.get(MailTemplate, id)
    |> Repo.delete()
  end

  defp update_history(mailing, admin) do
    history =
      from(
        m in MailTemplate,
        where: m.id == ^mailing.id,
        select: m.history
      )
      |> Repo.one()

    new_history =
      [%{editor: admin, time: AppCount.current_time()}]
      |> Enum.concat(history || [])

    Repo.get(MailTemplate, mailing.id)
    |> MailTemplate.changeset(%{history: new_history})
    |> Repo.update()
  end
end
