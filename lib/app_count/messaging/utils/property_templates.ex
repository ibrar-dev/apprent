defmodule AppCount.Messaging.Utils.PropertyTemplates do
  import Ecto.Query
  alias AppCount.Messaging.MailTemplate
  alias AppCount.Messaging.PropertyTemplate
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  def create_property_template(_, params) do
    %PropertyTemplate{}
    |> PropertyTemplate.changeset(params)
    |> Repo.insert!()
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

  def property_templates(admin, _) do
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
        template_id: t.id,
        subject: t.subject,
        body: t.body,
        creator: t.creator
      }
    )
    |> Repo.all()
  end

  def property_template(property_id) do
    template_query =
      from(
        pt in PropertyTemplate,
        where: pt.property_id == ^property_id,
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
        template_id: t.id,
        subject: t.subject,
        body: t.body,
        creator: t.creator
      }
    )
    |> Repo.all()
  end

  def templates_properties(template_id) do
    from(
      pt in PropertyTemplate,
      where: pt.template_id == ^template_id,
      select: %{
        property_id: pt.property_id
      }
    )
    |> Repo.all()
  end

  def delete_all_templates(template_id) do
    from(
      pt in PropertyTemplate,
      where: pt.template_id == ^template_id,
      select: %{
        id: pt.id,
        property_id: pt.property_id,
        template_id: pt.template_id
      }
    )
    |> Repo.delete_all()
  end
end
