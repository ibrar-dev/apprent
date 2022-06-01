defmodule Authorize.FilterAndTokenize do
  use Ecto.Schema
  import Ecto.Query
  alias AppCount.Repo

  def tokenize() do
    filters = [is_tokenized: false, active: true, type: "cc"]

    # list of the payment methods
    AppCount.Repo.all(
      from entries in AppCount.Accounts.PaymentSource,
        where: ^filters
    )
    |> Enum.filter(fn x -> date_is_valid?(x) end)
    |> Enum.map(fn x -> update_info(x) end)
  end

  def get_processor(payment_source) do
    payment_source.account_id
    |> get_account()
    |> lookup_property_id()
    |> lookup_processor()
  end

  def get_account(acct_id) do
    Repo.get(AppCount.Accounts.Account, acct_id)
  end

  def lookup_property_id(acct) when is_nil(acct) do
    nil
  end

  def lookup_property_id(acct) do
    AppCount.Accounts.get_property_id(acct)
  end

  def lookup_processor(id) when is_nil(id) do
    nil
  end

  def lookup_processor(property_id) do
    AppCount.Properties.Processors.fetch(property_id, :cc)
  end

  def update_info(payment_source) do
    processor = get_processor(payment_source)
    update_info(payment_source, processor)
  end

  def update_info(_payment_source, nil) do
    {:error, "No Processor for this payment source"}
  end

  def update_info(payment_source, processor) do
    case Authorize.CreateCustomer.create_profile(processor, payment_source) do
      {:ok, result} ->
        payment_source
        |> AppCount.Accounts.PaymentSource.changeset(%{
          num1: result.authorize_profile_id,
          num2: result.authorize_payment_profile_id,
          is_tokenized: true
        })
        |> AppCount.Repo.update()

      err ->
        err
    end
  end

  def date_is_valid?(map) do
    current_month = AppCount.current_date().month
    current_year = rem(AppCount.current_date().year, 100)

    [month, year] = String.split(map.exp, "/") |> Enum.map(fn x -> String.to_integer(x) end)

    cond do
      year > current_year ->
        true

      year == current_year and month >= current_month ->
        true

      year == current_year and month < current_month ->
        false

      year < current_year ->
        false
    end
  end
end
