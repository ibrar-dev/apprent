defmodule Payscape.CreateAccount do
  alias Payscape.Request

  @enforce_keys [
    :email,
    :phone,
    :business_name,
    :address,
    :city,
    :state,
    :zip,
    :account_name,
    :account_number,
    :routing_number,
    :bank_name,
    :account_type,
    :account_ownership_type,
    :ein
  ]
  defstruct [
    :email,
    :phone,
    :business_name,
    :address,
    :city,
    :state,
    :zip,
    :account_name,
    :account_number,
    :routing_number,
    :bank_name,
    :account_type,
    :account_ownership_type,
    :ein,
    :description,
    country: "USA",
    account_country_code: "USA"
  ]

  def create(processor, params) do
    params
    |> request()
    |> Jason.encode!()
    |> Request.request(processor, "propayapi/signup", :put)
    |> case do
      {:ok, body} -> {:ok, Jason.decode!(body)}
      e -> e
    end
  end

  def request(params) do
    %{
      PersonalData: %{
        SourceEmail: params.email,
        PhoneInformation: %{
          DayPhone: params.phone
        }
      },
      SignupAccountData: %{
        Tier: "Consolidated"
      },
      BusinessData: %{
        BusinessLegalName: params.business_name,
        EIN: params.ein
      },
      BusinessAddress: %{
        Address1: params.address,
        City: params.city,
        State: params.state,
        Country: params.country,
        Zip: params.zip
      },
      BankAccount: %{
        AccountCountryCode: params.account_country_code || "USA",
        BankAccountNumber: params.account_number,
        RoutingNumber: params.routing_number,
        AccountOwnershipType: params.account_ownership_type,
        BankName: params.bank_name,
        AccountType: params.account_type,
        AccountName: params.account_name,
        Description: params.description
      }
    }
  end
end
