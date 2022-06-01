defmodule AppCount.Accounting.SpecialAccounts do
  alias AppCount.Accounting.AccountRepo
  alias AppCount.Ledgers.ChargeCodeRepo
  alias AppCount.Accounting.Account

  @special_accounts %{
    rent: "Rent",
    hap_rent: "HAP Rent",
    late_fees: "Late Fees",
    admin_fees: "Administration Fees Income",
    application_fees: "Application Fees Income",
    nsf_fees: "NSF Fees Income",
    eviction: "Legal/Eviction Fees",
    mtm_fees: "Month to Month Fees",
    sec_dep_clearing: "Security Deposit Clearing",
    sec_dep_fee: "Security Deposit Refundable"
  }
  @special_account_charge_codes %{
    rent: "rent",
    hap_rent: "HAPrent",
    late_fees: "late",
    admin_fees: "admin",
    application_fees: "app",
    nsf_fees: "nsf",
    mtm_fees: "mtm",
    sec_dep_fee: "secdep",
    sec_dep_clearing: "secexch"
  }

  def init_accounts do
    for {_key, name} <- @special_accounts do
      get_or_insert_account(name)
      #      charge_code = get_or_insert_default_charge_code(account, key)
      #
      #      {
      #        key,
      #        [account, charge_code]
      #      }
    end

    :ok
  end

  def get_account(key) when is_atom(key) do
    @special_accounts
    |> Map.fetch!(key)
    |> get_or_insert_account()
  end

  def get_charge_code(key) when is_atom(key) do
    account = get_account(key)
    get_or_insert_default_charge_code(account, key)
  end

  defp get_or_insert_account(name) do
    get_account_by_name(name) || insert_account_by_name(name)
  end

  def get_account_by_name(name) do
    AccountRepo.get_by(name: name)
  end

  def insert_account_by_name(name) do
    {:ok, %Account{} = account} = AccountRepo.insert(%{name: name})

    account
  end

  defp get_or_insert_default_charge_code(%Account{} = account, key) do
    code = @special_account_charge_codes[key]

    if code do
      # Note: this will fail if we already have this charge code in the system
      # associated with another account. In all likelihood this will never
      # happen, if it does it's not clear how we should handle it.
      case ChargeCodeRepo.get_by(account_id: account.id, code: code) do
        %{is_default: true} = c ->
          c

        %{is_default: false} = c ->
          {:ok, charge_code} = ChargeCodeRepo.update(c, %{is_default: true})

          charge_code

        nil ->
          {:ok, charge_code} =
            ChargeCodeRepo.insert(%{
              account_id: account.id,
              is_default: true,
              code: code,
              name: account.name
            })

          charge_code
      end
    end
  end
end
