defmodule AppCount.Prospects.Utils.Memos do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Prospects.Memo
  alias AppCount.Core.ClientSchema

  def list_memos(admin) do
    # TODO:SCHEMA remove dasmen
    from(
      m in Memo,
      join: p in assoc(m, :prospect),
      select: %{
        id: m.id,
        admin: m.admin,
        contact_date: m.inserted_at,
        notes: m.notes,
        prospect: %{
          id: p.id,
          name: p.name,
          email: p.email,
          phone: p.phone,
          notes: p.notes
        }
      },
      where: p.property_id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin))
    )
    |> Repo.all()
  end

  def create_memo(params) do
    %Memo{}
    |> Memo.changeset(params)
    |> Repo.insert()
    |> send_email(params["send"])
  end

  def send_email({:ok, memo}, send) do
    if send do
      from(
        m in Memo,
        join: p in assoc(m, :prospect),
        join: prop in assoc(p, :property),
        left_join: l in assoc(prop, :logo_url),
        left_join: i in assoc(prop, :icon_url),
        select: %{
          notes: m.notes,
          admin: m.admin,
          prospect: p,
          property: merge(prop, %{icon: i.url, logo: l.url})
        },
        where: m.id == ^memo.id,
        limit: 1
      )
      |> Repo.one()
      |> AppCountCom.Prospects.contact_prospect()
    end

    {:ok, memo}
  end

  def send_email(e, _), do: e
end
