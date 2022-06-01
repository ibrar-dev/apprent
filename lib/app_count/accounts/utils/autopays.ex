defmodule AppCount.Accounts.Utils.Autopays do
  import Ecto.Query
  alias AppCount.Accounts.Autopay
  alias AppCount.Core.TenantTopic
  alias AppCount.Repo

  def create_autopay(params) do
    params
    |> build_autopay_event_content()
    |> publish_autopay_event()

    %Autopay{}
    |> Autopay.changeset(params)
    |> Repo.insert()
  end

  def update_autopay(id, params) do
    params
    |> build_autopay_event_content()
    |> publish_autopay_event()

    Repo.get(Autopay, id)
    |> Autopay.changeset(params)
    |> Repo.update()
  end

  def inactive_autopay(id, params) do
    new_params = Map.merge(params, %{active: false})

    update_autopay(id, new_params)
  end

  def activate_autopay(id, params) do
    new_params = Map.merge(params, %{active: true})

    update_autopay(id, new_params)
  end

  def get_autopay_info(account_id) do
    from(
      a in Autopay,
      join: ps in assoc(a, :payment_source),
      on: a.account_id == ps.account_id,
      where: a.account_id == ^account_id,
      select: %{
        id: a.id,
        account_id: a.account_id,
        active: a.active,
        agreement_text: a.agreement_text,
        agreement_accepted_at: a.agreement_accepted_at,
        payer_ip_address: a.payer_ip_address,
        payment_method:
          map(ps, [
            :id,
            :type,
            :name,
            :num1,
            :num2,
            :is_tokenized,
            :last_4,
            :exp,
            :brand,
            :active,
            :account_id
          ])
      }
    )
    |> Repo.one()
  end

  # This will only run when autopay is turned on and off. It is used to notify the tenant that autopay ahs been turned on or off.
  defp build_autopay_event_content(%{tenant_id: tenant_id} = params) do
    _content = %{
      subject_id: tenant_id,
      subject_name: AppCount.Tenants.Tenant,
      changes: params
    }
  end

  defp build_autopay_event_content(params) do
    params
  end

  defp publish_autopay_event(
         %{subject_id: _tenant_id, subject_name: AppCount.Tenants.Tenant, changes: _changes} =
           content
       ) do
    TenantTopic.changed(content, __MODULE__)
  end

  defp publish_autopay_event(_), do: nil
end
