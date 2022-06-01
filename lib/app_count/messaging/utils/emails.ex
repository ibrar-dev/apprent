defmodule AppCount.Messaging.Utils.Emails do
  alias AppCount.Messaging.Email
  alias AppCount.Tenants.Tenant
  alias AppCount.Repo
  import Ecto.Query

  def create_email(params) do
    %Email{}
    |> Email.changeset(params)
    |> Repo.insert()
  end

  def find_tenants({_, email}) do
    find_tenants(email)
  end

  def find_tenants(email) do
    from(t in Tenant, where: t.email == ^email)
    |> Repo.all()
  end

  def list_emails(tenant_id) do
    from(
      e in Email,
      where: e.tenant_id == ^tenant_id,
      select: map(e, [:id, :body, :attachments, :subject, :to, :from, :inserted_at]),
      order_by: [
        desc: e.inserted_at
      ]
    )
    |> Repo.all()
  end
end
