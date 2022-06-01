defmodule AppCount.Finance.AccountAttributesFromNumberTest do
  alias AppCount.Finance.AccountAttributesFromNumber, as: Subject
  use AppCount.Case, async: true

  describe "get_attrs/2" do
    test "11* - bank account and cash" do
      args = %{description: "Operating Account", number: "11100000"}

      assert %{
               natural_balance: "debit",
               type: "Asset",
               number: "11100000",
               subtype: "Bank Accounts / Cash",
               name: "Operating Account",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "119* - other current assets" do
      args = %{description: "Rent Receivable", number: "11960000"}

      assert %{
               natural_balance: "debit",
               type: "Asset",
               number: "11960000",
               subtype: "Other Current Assets",
               name: "Rent Receivable",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "14X account with array description" do
      args = %{description: ["Accumulated Depr - FF", "&E 5 yrs"], number: "14050001"}

      assert %{
               natural_balance: "debit",
               type: "Asset",
               number: "14050001",
               subtype: "Property Assets",
               name: "Accumulated Depr - FF &E 5 yrs",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "2* - Liabilities and Capital" do
      args = %{description: "Accounts Payable", number: "21010000"}

      assert %{
               natural_balance: "credit",
               type: "Liability",
               number: "21010000",
               subtype: "Liabilities",
               name: "Accounts Payable",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "3* - Capital & Equity" do
      args = %{description: "Contribution - Investor", number: "30001000"}

      assert %{
               natural_balance: "credit",
               type: "Equity",
               number: "30001000",
               subtype: "Capital & Equity",
               name: "Contribution - Investor",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "40* - management fees" do
      args = %{description: "DMR Management Fees", number: "40760000"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "40760000",
               subtype: "Management Fees",
               name: "DMR Management Fees",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "411* - Rent Possible" do
      args = %{description: "Gross Potential Rent", number: "41110005"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "41110005",
               subtype: "Gross Rent Possible",
               name: "Gross Potential Rent",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "412* - Rent Possible" do
      args = %{description: "HAP Rent", number: "41290001"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "41290001",
               subtype: "Rental Income",
               name: "HAP Rent",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "413* - Rent Possible" do
      args = %{description: "Less: Move In Concession", number: "41300001"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "41300001",
               subtype: "Rental Income",
               name: "Less: Move In Concession",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "414* - Rent Possible" do
      args = %{description: "Less: Vacancy", number: "41400000"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "41400000",
               subtype: "Rental Income",
               name: "Less: Vacancy",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "415* - Rent Possible" do
      args = %{description: "Less: Model Units", number: "41500000"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "41500000",
               subtype: "Rental Income",
               name: "Less: Model Units",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "416* - Rent Possible" do
      args = %{description: "Less: Down Units", number: "41600000"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "41600000",
               subtype: "Rental Income",
               name: "Less: Down Units",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "417* - Rent Possible" do
      args = %{description: "Plus: Prepaid Rent", number: "41760000"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "41760000",
               subtype: "Rental Income",
               name: "Plus: Prepaid Rent",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "4211* - Utilities" do
      args = %{description: "Cable Income", number: "42110001"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "42110001",
               subtype: "Utilities Income",
               name: "Cable Income",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "4213 - Administrative Income" do
      args = %{description: "Application Fees", number: "42130002"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "42130002",
               subtype: "Administrative Income",
               name: "Application Fees",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "4215* - Amenities Income" do
      args = %{description: "Pet Rent Income", number: "42150006"}

      assert %{
               natural_balance: "credit",
               type: "Revenue",
               number: "42150006",
               subtype: "Amenities Income",
               name: "Pet Rent Income",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "50* - General and Administrative" do
      args = %{description: "Credit Reports / Resident Screening", number: "50060000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "50060000",
               subtype: "Operational - General and Administrative",
               name: "Credit Reports / Resident Screening",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "5080 -  Contract Services" do
      args = %{description: "Grounds Maintenance", number: "50801000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "50801000",
               subtype: "Operational - Contract Services",
               name: "Grounds Maintenance",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "511 -  Advertising and Marketing" do
      args = %{description: "Internet Advertising", number: "51110000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "51110000",
               subtype: "Operational - Advertising and Marketing",
               name: "Internet Advertising",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "512 -  Advertising and Marketing" do
      args = %{description: "Social Media Marketing", number: "51240000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "51240000",
               subtype: "Operational - Advertising and Marketing",
               name: "Social Media Marketing",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "513 - Payroll" do
      args = %{description: "Office Salaries", number: "51360000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "51360000",
               subtype: "Operational - Payroll",
               name: "Office Salaries",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "514 - Payroll" do
      args = %{description: "Employee Bonus", number: "51400000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "51400000",
               subtype: "Operational - Payroll",
               name: "Employee Bonus",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "515 - Payroll" do
      args = %{description: "Time Management Software", number: "51510000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "51510000",
               subtype: "Operational - Payroll",
               name: "Time Management Software",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "522 - Utilities" do
      args = %{description: "Electricity - Common Areas", number: "52210000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "52210000",
               subtype: "Operational - Utilities",
               name: "Electricity - Common Areas",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "53 - Repairs and Maintenance" do
      args = %{description: "Electrical Supplies", number: "53110002"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "53110002",
               subtype: "Operational - Repairs and Maintenance",
               name: "Electrical Supplies",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "5401 - Make Ready" do
      args = %{description: "Turnover Cleaning", number: "54010004"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "54010004",
               subtype: "Operational - Make Ready",
               name: "Turnover Cleaning",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "5405 - Taxes and Insurance" do
      args = %{description: "Real Estate Taxes", number: "54051000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "54051000",
               subtype: "Operational - Taxes and Insurance",
               name: "Real Estate Taxes",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "5407 - Management Fees" do
      args = %{description: "Management Fees", number: "54071000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "54071000",
               subtype: "Operational - Management Fees",
               name: "Management Fees",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "9012 unit turns" do
      args = %{description: "Water Damage Repairs", number: "90121050"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "90121050",
               subtype: "Non-Operational - Unit Turns",
               name: "Water Damage Repairs",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "90125 Other Capital Expenses" do
      args = %{description: "Amenities Upgrade", number: "90125313"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "90125313",
               subtype: "Non-Operational - Capital Expenses",
               name: "Amenities Upgrade",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "902 Other Non-Operational Expenses" do
      args = %{description: "Depreciation Expense", number: "90210000"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "90210000",
               subtype: "Non-Operational - Other Non-Operational Expenses",
               name: "Depreciation Expense",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "9201 Mortgage Interest" do
      args = %{description: "Mortgage Interest", number: "92013010"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92013010",
               subtype: "Non-Operational - Mortgage Interest",
               name: "Mortgage Interest",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "92021 Unit Renovations" do
      args = %{description: "Reno Unit Upgrade", number: "92021001"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92021001",
               subtype: "Non-Operational - Unit Renovations",
               name: "Reno Unit Upgrade",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "92022 Clubhouse Renovations" do
      args = %{description: "Reno CH Electrical", number: "92022010"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92022010",
               subtype: "Non-Operational - Clubhouse Renovations",
               name: "Reno CH Electrical",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "92023 Dog Park Renovations" do
      args = %{description: "Reno Dog Park", number: "92023010"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92023010",
               subtype: "Non-Operational - Dog Park Renovations",
               name: "Reno Dog Park",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "92024 Playground Renovations" do
      args = %{description: "Reno Playground", number: "92024010"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92024010",
               subtype: "Non-Operational - Playground Renovations",
               name: "Reno Playground",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "92025 Exterior Renovations" do
      args = %{description: "Reno Full Building", number: "92025005"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92025005",
               subtype: "Non-Operational - Exterior Renovations",
               name: "Reno Full Building",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "92026 Path Renovations" do
      args = %{description: "Reno Path", number: "92026001"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92026001",
               subtype: "Non-Operational - Path Renovations",
               name: "Reno Path",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "92027 Roof Renovations" do
      args = %{description: "Reno Roof", number: "92027010"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92027010",
               subtype: "Non-Operational - Roof Renovations",
               name: "Reno Roof",
               description: ""
             } == Subject.get_attrs(args)
    end

    test "92028 Other Renovations" do
      args = %{description: "Reno Trash/Dumpster Removal", number: "92028010"}

      assert %{
               natural_balance: "debit",
               type: "Expense",
               number: "92028010",
               subtype: "Non-Operational - Other Renovations",
               name: "Reno Trash/Dumpster Removal",
               description: ""
             } == Subject.get_attrs(args)
    end
  end
end
