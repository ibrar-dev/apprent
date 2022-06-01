defmodule AppCount.Ledgers.Utils.SpecialChargeCodes do
  alias AppCount.Ledgers.ChargeCodeRepo
  alias AppCount.Accounting.Account
  alias AppCount.Core.ClientSchema

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
  @special_charge_code_keys Map.keys(@special_account_charge_codes)

  def special_charge_code_list() do
    @special_account_charge_codes
  end

  def get_charge_code(key) when key in @special_charge_code_keys do
    account = AppCount.Accounting.SpecialAccounts.get_account(key)
    get_or_insert_default_charge_code(ClientSchema.new("dasmen", account), key)
  end

  def get_charge_code(_key), do: nil

  defp get_or_insert_default_charge_code(
         %AppCount.Core.ClientSchema{name: client_schema, attrs: %Account{} = account},
         key
       ) do
    code = @special_account_charge_codes[key]

    if code do
      # Note: this will fail if we already have this charge code in the system
      # associated with another account. In all likelihood this will never
      # happen, if it does it's not clear how we should handle it.
      case ChargeCodeRepo.get_by([account_id: account.id, code: code], prefix: client_schema) do
        %{is_default: true} = c ->
          c

        %{is_default: false} = c ->
          {:ok, charge_code} =
            ChargeCodeRepo.update(c, %{is_default: true}, prefix: client_schema)

          charge_code

        nil ->
          {:ok, charge_code} =
            ChargeCodeRepo.insert(
              %{
                account_id: account.id,
                is_default: true,
                code: code,
                name: account.name
              },
              prefix: client_schema
            )

          charge_code
      end
    end
  end
end
