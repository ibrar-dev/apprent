defmodule AppCount.Finance.AccountAttributesFromNumber do
  @moduledoc """
  Getting accounts from Yardi gives us a big old list of maps like this:

    %{description: "Some account", number: "12345678"}

  In some cases, `description` is a list of 2 or more strings.

  Given number and name, we want to make some predictions about the account
  natural balance, type, subtype, etc. This is useful when either creating new
  accounts or when updating existing accounts in the database (in case the
  accountants want to change the number).
  """

  def get_attrs(%{description: description, number: number}) do
    name = normalized_description(description)
    get_attrs(name, number)
  end

  # 119XXXXX - other current assets
  def get_attrs(name, "119" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Asset",
      subtype: "Other Current Assets",
      description: "",
      number: number
    }
  end

  # 11XXXXXX - Bank accounts
  def get_attrs(name, "11" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Asset",
      subtype: "Bank Accounts / Cash",
      description: "",
      number: number
    }
  end

  # 1XXXXXXX - all other assets, esp. property assets
  def get_attrs(name, "1" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Asset",
      subtype: "Property Assets",
      description: "",
      number: number
    }
  end

  # 2XXXXX - Liabilities
  def get_attrs(name, "2" <> _rest = number) do
    %{
      name: name,
      natural_balance: "credit",
      type: "Liability",
      subtype: "Liabilities",
      description: "",
      number: number
    }
  end

  # 3XXXXX - Equity
  def get_attrs(name, "3" <> _rest = number) do
    %{
      name: name,
      natural_balance: "credit",
      type: "Equity",
      subtype: "Capital & Equity",
      description: "",
      number: number
    }
  end

  # 40X - management fees income
  def get_attrs(name, "40" <> _rest = number) do
    %{
      name: name,
      natural_balance: "credit",
      type: "Revenue",
      subtype: "Management Fees",
      description: "",
      number: number
    }
  end

  # 411 - Gross Rent Possible
  def get_attrs(name, "411" <> _rest = number) do
    %{
      name: name,
      natural_balance: "credit",
      type: "Revenue",
      subtype: "Gross Rent Possible",
      description: "",
      number: number
    }
  end

  # 412 - 41X - Rental Income
  def get_attrs(name, "41" <> _rest = number) do
    %{
      name: name,
      natural_balance: "credit",
      type: "Revenue",
      subtype: "Rental Income",
      description: "",
      number: number
    }
  end

  # 4211 -> Utilities Income
  def get_attrs(name, "4211" <> _rest = number) do
    %{
      name: name,
      natural_balance: "credit",
      type: "Revenue",
      subtype: "Utilities Income",
      description: "",
      number: number
    }
  end

  # 4213 -> Administrative income
  def get_attrs(name, "4213" <> _rest = number) do
    %{
      name: name,
      natural_balance: "credit",
      type: "Revenue",
      subtype: "Administrative Income",
      description: "",
      number: number
    }
  end

  # 4215 - Amenities Income
  def get_attrs(name, "4215" <> _rest = number) do
    %{
      name: name,
      natural_balance: "credit",
      type: "Revenue",
      subtype: "Amenities Income",
      description: "",
      number: number
    }
  end

  # 511 - Advertising and Marketing
  def get_attrs(name, "511" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Advertising and Marketing",
      description: "",
      number: number
    }
  end

  # 512 - Advertising and Marketing
  def get_attrs(name, "512" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Advertising and Marketing",
      description: "",
      number: number
    }
  end

  # 513 - Payroll
  def get_attrs(name, "513" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Payroll",
      description: "",
      number: number
    }
  end

  # 514 - Payroll
  def get_attrs(name, "514" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Payroll",
      description: "",
      number: number
    }
  end

  # 515 - Payroll
  def get_attrs(name, "515" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Payroll",
      description: "",
      number: number
    }
  end

  # 522 - Utilities
  def get_attrs(name, "52" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Utilities",
      description: "",
      number: number
    }
  end

  # 53 - Repairs and Maintenance
  def get_attrs(name, "53" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Repairs and Maintenance",
      description: "",
      number: number
    }
  end

  # 5401 - Make Ready
  def get_attrs(name, "5401" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Make Ready",
      description: "",
      number: number
    }
  end

  # 5405 - Taxes and Insurance
  def get_attrs(name, "5405" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Taxes and Insurance",
      description: "",
      number: number
    }
  end

  # 5407 - Management Fees
  def get_attrs(name, "5407" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Management Fees",
      description: "",
      number: number
    }
  end

  # 5080 - Contract Services
  def get_attrs(name, "5080" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - Contract Services",
      description: "",
      number: number
    }
  end

  # 50* - General and Administrative
  def get_attrs(name, "50" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Operational - General and Administrative",
      description: "",
      number: number
    }
  end

  # 90125 - Capital Expenses
  def get_attrs(name, "90125" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Capital Expenses",
      description: "",
      number: number
    }
  end

  # 9012 - unit turns
  def get_attrs(name, "9012" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Unit Turns",
      description: "",
      number: number
    }
  end

  # 902 - Capital Expenses
  def get_attrs(name, "90" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Other Non-Operational Expenses",
      description: "",
      number: number
    }
  end

  # 92028 Other Renovations
  def get_attrs(name, "92028" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Other Renovations",
      description: "",
      number: number
    }
  end

  # 92027 Roof Renovations
  def get_attrs(name, "92027" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Roof Renovations",
      description: "",
      number: number
    }
  end

  # 92026 Path Renovations
  def get_attrs(name, "92026" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Path Renovations",
      description: "",
      number: number
    }
  end

  # 92025 Exterior Renovations
  def get_attrs(name, "92025" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Exterior Renovations",
      description: "",
      number: number
    }
  end

  # 92024 Playground Renovations
  def get_attrs(name, "92024" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Playground Renovations",
      description: "",
      number: number
    }
  end

  # 92023 Dog Park Renovations
  def get_attrs(name, "92023" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Dog Park Renovations",
      description: "",
      number: number
    }
  end

  # 92022 Clubhouse Renovations
  def get_attrs(name, "92022" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Clubhouse Renovations",
      description: "",
      number: number
    }
  end

  # 92021 Unit Renovations
  def get_attrs(name, "92021" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Unit Renovations",
      description: "",
      number: number
    }
  end

  # 9201 - Mortgage Interest
  def get_attrs(name, "9201" <> _rest = number) do
    %{
      name: name,
      natural_balance: "debit",
      type: "Expense",
      subtype: "Non-Operational - Mortgage Interest",
      description: "",
      number: number
    }
  end

  # Private Helper Methods

  # Description sometimes comes as an array of strings, so we want to handle
  # that appropriately.
  defp normalized_description(descr) when is_binary(descr) do
    descr
  end

  defp normalized_description(descr) when is_list(descr) do
    Enum.join(descr, " ")
  end

  defp normalized_description(_) do
    ""
  end
end
