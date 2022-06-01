defmodule AppCountAuth.Users.Tenant do
  defstruct [
    :tenant_account_id,
    :client_schema,
    :features,
    :user_id,
    :password_changed,
    :autopay,
    :receives_mailings,
    :uuid,
    :profile_pic,
    :preferred_language,
    :id,
    :email,
    :first_name,
    :last_name,
    :phone,
    :alarm_code,
    :payment_status,
    :account_id,
    :name,
    :property,
    :active
  ]
end
