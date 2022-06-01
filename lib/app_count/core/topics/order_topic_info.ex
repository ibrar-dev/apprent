defmodule AppCount.Core.OrderTopic.Info do
  @moduledoc """
  Info has no business rules.
  It just passes the required data while decoupling that data from the core struct types
  """
  alias AppCount.Maintenance.Order
  alias AppCount.Tenants.Tenant
  alias AppCount.Accounts.Account
  alias AppCount.Core.OrderTopic.Info

  @default_tech_name "Tech not yet assigned"
  @required [
    :phone_to,
    :account_allow_sms,
    :order_allow_sms,
    :order_id,
    :first_name,
    :work_order_category_name,
    :property_name
  ]

  @fields [:tech_name | @required]

  @enforce_keys @required
  defstruct @fields

  # function definition
  def new(tenant, account, order, tech_name \\ @default_tech_name)

  def new(
        nil = _no_tenant,
        nil = _no_account,
        %Order{
          allow_sms: order_allow_sms,
          id: order_id,
          category: %{name: work_order_category_name},
          property: %{name: property_name}
        },
        tech_name
      ) do
    %Info{
      phone_to: :not_available,
      account_allow_sms: false,
      order_allow_sms: order_allow_sms,
      order_id: order_id,
      first_name: :not_available,
      work_order_category_name: work_order_category_name,
      tech_name: tech_name,
      property_name: property_name
    }
  end

  def new(
        %Tenant{phone: nil} = tenant,
        account,
        order,
        tech_name
      ) do
    tenant = %{tenant | phone: :not_available}
    new(tenant, account, order, tech_name)
  end

  def new(
        %Tenant{phone: phone_to, first_name: first_name},
        nil = _no_account,
        %Order{
          allow_sms: order_allow_sms,
          id: order_id,
          category: %{name: work_order_category_name},
          property: %{name: property_name}
        },
        tech_name
      ) do
    %Info{
      phone_to: phone_to,
      account_allow_sms: :no_account,
      order_allow_sms: order_allow_sms,
      order_id: order_id,
      first_name: first_name,
      work_order_category_name: work_order_category_name,
      tech_name: tech_name,
      property_name: property_name
    }
  end

  def new(
        %Tenant{phone: phone_to, first_name: first_name},
        %Account{allow_sms: account_allow_sms},
        %Order{
          allow_sms: order_allow_sms,
          id: order_id,
          category: %{name: work_order_category_name},
          property: %{name: property_name}
        },
        tech_name
      ) do
    %Info{
      phone_to: phone_to,
      account_allow_sms: account_allow_sms,
      order_allow_sms: order_allow_sms,
      order_id: order_id,
      first_name: first_name,
      work_order_category_name: work_order_category_name,
      tech_name: tech_name,
      property_name: property_name
    }
  end

  def eval_string(
        message,
        %Info{
          first_name: first_name,
          work_order_category_name: work_order_category_name,
          tech_name: tech_name,
          order_id: order_id,
          property_name: property_name
        }
      ) do
    bindings = [
      first_name: first_name,
      work_order_category_name: work_order_category_name,
      tech_name: tech_name,
      order_url: Order.url(order_id),
      property_name: property_name
    ]

    EEx.eval_string(message, bindings)
  end
end
