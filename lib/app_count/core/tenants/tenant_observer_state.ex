defmodule AppCount.Core.TenantObserver.State do
  @moduledoc false
  require Logger
  alias AppCount.Core.TenantObserver.State
  alias AppCount.Core.ClientSchema
  alias AppCount.Core.PhoneNumber

  @deps %{
    tenant_repo: AppCount.Tenants.TenantRepo,
    state: AppCount.Core.TenantObserver.State,
    mailer: AppCountCom.Tenants,
    properties: AppCount.Properties
  }

  defstruct deps: @deps, outgoing_message: nil, phone_tenant_map: %{}

  # phone_tenant_map = %{
  #  {"+15552223333" => [ tenant1_id,  tenant2_id, ... ]} ,
  #  {"+15552224444" => [ tenant4_id ]} }

  def payment_status_changed_to_cash(
        tenant_id,
        %State{deps: %{tenant_repo: tenant_repo, mailer: mailer, properties: properties}} = state
      ) do
    {:ok, tenant} = tenant_repo.aggregate(tenant_id)

    # Assuming a Tenant, turn off their autopay (if it exists)
    _result = tenant_repo.revoke_autopay(tenant)

    ##### Send the email to let the tenant know
    # Mailer expects property to have the shape that comes out of this function,
    # rather than more conventional property struct.
    # We also use this method to account for possible wackiness with tenancies,
    # e.g. a tenant has moved between properties
    property_id = tenant_repo.property_for_tenant(tenant.id).id
    property = properties.get_property(ClientSchema.new("dasmen", property_id))

    mail = mailer.tenant_marked_as_cash_only(%{tenant: tenant, property: property})

    # Return the emitted message in case someone needs it
    put_state(state, outgoing_message: mail)
  end

  # Triggered on the last day of the month
  def last_day_of_month(_tenant_id, state) do
    # template = email_template_one_day_before_autopay(tenant_id)
    # (1) get all autopay active tenants.
    # (2) template = email_template_autopay_will_happen_tomorrow(tenant_id)
    # (3) EACH _tenant_id -> email(may be nil or empty), send email text

    # mailer.autopay_reminder(%{property: property, tenant: tenant_aggregate})
    state
  end

  # Send a message upon Autopay being set up
  def autopay_activated_notification(
        tenant_id,
        %State{deps: %{tenant_repo: tenant_repo, mailer: mailer, properties: properties}} = state
      ) do
    {:ok, tenant} = tenant_repo.aggregate(tenant_id)
    property_id = tenant_repo.property_for_tenant(tenant.id).id
    property = properties.get_property(ClientSchema.new("dasmen", property_id))

    mail = mailer.autopay_activated(%{property: property, tenant: tenant})

    put_state(state, outgoing_message: mail)
  end

  # Send a message upon Autopay being deactivated
  def autopay_deactivated_notification(
        tenant_id,
        %State{deps: %{tenant_repo: tenant_repo, mailer: mailer, properties: properties}} = state
      ) do
    {:ok, tenant} = tenant_repo.aggregate(tenant_id)
    property_id = tenant_repo.property_for_tenant(tenant.id).id
    property = properties.get_property(ClientSchema.new("dasmen", property_id))

    mail = mailer.autopay_deactivated(%{property: property, tenant: tenant})

    put_state(state, outgoing_message: mail)
  end

  def update_invalid_phone_numbers(
        %{phone: phone},
        %State{phone_tenant_map: phone_tenant_map, deps: %{tenant_repo: tenant_repo}} = state
      ) do
    phone_tenant_map
    |> Map.get(phone, [])
    |> Enum.each(fn tenant_id ->
      tenant_id
      |> tenant_repo.get()
      |> tenant_repo.update(%{invalid_phone: phone})
    end)

    state
  end

  def load_phone_tenant_map(%State{deps: %{tenant_repo: tenant_repo}} = state) do
    phone_tenant_map =
      tenant_repo.all()
      |> Enum.reduce(%{}, fn tenant, acc ->
        phone = PhoneNumber.new(tenant.phone)

        if PhoneNumber.valid?(phone) do
          canonical_phone = PhoneNumber.dial_string(phone)
          list = Map.get(acc, canonical_phone, [])
          Map.put(acc, canonical_phone, [tenant.id | list])
        else
          acc
        end
      end)

    %{state | phone_tenant_map: phone_tenant_map}
  end

  # Usage: put_state(some_state, foo: "bar") -> %State{foo: "bar", ...other-stuff}
  defp put_state(%State{} = state, opts) do
    struct(state, opts)
  end
end
