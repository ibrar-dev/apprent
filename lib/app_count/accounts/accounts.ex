defmodule AppCount.Accounts do
  alias AppCount.Accounts.Utils.Accounts
  alias AppCount.Accounts.Utils.PaymentSources
  alias AppCount.Accounts.Utils.Payments
  alias AppCount.Accounts.Utils.Tokens
  alias AppCount.Accounts.Utils.AccountInfo
  alias AppCount.Accounts.Utils.Passwords
  alias AppCount.Accounts.Utils.Locks
  alias AppCount.Accounts.Utils.Logins
  alias AppCount.Accounts.Utils.Stats
  alias AppCount.Accounts.Utils.Autopays
  alias AppCount.Accounts.LockRepo

  def create_tenant_account(tenant_id), do: Accounts.create_tenant_account(tenant_id)
  def update_account(id, params), do: Accounts.update_account(id, params)
  def get_account(tenant_id), do: Accounts.get_account(tenant_id)
  def delete_account(id), do: Accounts.delete_account(id)
  def verify_tenant(params), do: Accounts.verify_tenant(params)

  # This lets us reset all accounts for when we migrate to the new AppRent
  def reset_all_accounts(property_ids), do: Accounts.reset_all_accounts(property_ids)

  def authenticate_account(username, password),
    do: Accounts.authenticate_account(username, password)

  def unit_info(tenant_id), do: Accounts.unit_info(tenant_id)
  def account_lock(account_id), do: LockRepo.account_lock(account_id)

  def active_lock(account_id), do: LockRepo.active_lock(account_id)

  def account_lock_exists?(account_id), do: LockRepo.account_locked(account_id)

  def get_property_id(%AppCount.Accounts.Account{uuid: uuid}) do
    get_property_id(uuid)
  end

  def get_property_id(uuid), do: Accounts.get_property_id(uuid)
  def send_welcome_email(account_id), do: Accounts.send_welcome_email(account_id)

  def reset_password_request(email), do: Passwords.reset_password_request(email)

  def reset_password(token, password, confirmation),
    do: Passwords.reset_password(token, password, confirmation)

  def create_payment_source(params), do: PaymentSources.create_payment_source(params)
  def list_payment_sources(tenant_id), do: PaymentSources.list_payment_sources(tenant_id)
  def update_payment_source(id, params), do: PaymentSources.update_payment_source(id, params)
  def delete_payment_source(id, false), do: PaymentSources.delete_payment_source(id, false)
  def delete_payment_source(id), do: PaymentSources.delete_payment_source(id)
  def get_payment_source(tenant_id, id), do: PaymentSources.get_payment_source(tenant_id, id)

  def get_default_payment_source(tenant_id),
    do: PaymentSources.get_default_payment_source(tenant_id)

  def set_default_payment_source(account, id),
    do: PaymentSources.set_default_payment_source(account, id)

  def list_payments(user_id, limit \\ nil), do: Payments.list_payments(user_id, limit)
  def create_payment(params), do: Payments.create_payment(params)

  def get_token(user_email), do: Tokens.get_token(user_email)
  def verify_token(token), do: Tokens.verify_token(token)

  def user_balance(user_id), do: AccountInfo.user_balance(user_id)
  def user_balance_total(user_id), do: AccountInfo.user_balance_total(user_id)
  def get_documents(user_id), do: AccountInfo.get_documents(user_id)
  def get_orders(user_id), do: AccountInfo.get_orders(user_id)
  def get_order(user_id, id), do: AccountInfo.get_order(user_id, id)
  def get_assignment(user_id, id), do: AccountInfo.get_assignment(user_id, id)
  def create_order(user_id, params), do: AccountInfo.create_order(user_id, params)

  def update_order(user_id, id, params), do: AccountInfo.update_order(user_id, id, params)
  def delete_order(user_id, id), do: AccountInfo.delete_order(user_id, id)

  def create_lock(params), do: Locks.create_lock(params)
  def update_lock(id, params), do: Locks.update_lock(id, params)
  def delete_lock(id), do: Locks.delete_lock(id)
  def lock_account(tenant_id, reason), do: Locks.lock_account(tenant_id, reason)

  def create_login(params), do: Logins.create_login(params)

  def admin_stats(admin, property_ids \\ nil), do: Stats.admin_stats(admin, property_ids)

  ## AUTOPAYS
  def create_autopay(params), do: Autopays.create_autopay(params)
  def update_autopay(id, params), do: Autopays.update_autopay(id, params)
  def inactive_autopay(id, params), do: Autopays.inactive_autopay(id, params)
  def activate_autopay(id, params), do: Autopays.activate_autopay(id, params)
  def get_autopay_info(account_id), do: Autopays.get_autopay_info(account_id)
end
