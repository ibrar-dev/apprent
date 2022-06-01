defmodule AppCount.LedgersFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def batch_factory do
        %AppCount.Ledgers.Batch{
          property: build(:property),
          bank_account: build(:bank_account)
        }
      end

      def payment_factory do
        %AppCount.Ledgers.Payment{
          amount: 50,
          transaction_id: "SomeId",
          post_month: Timex.beginning_of_month(AppCount.current_date()),
          source: "web",
          surcharge: 0,
          response: %{},
          description: "Generic Payment",
          property: build(:property),
          customer_ledger: build(:customer_ledger)
        }
      end

      def charge_code_factory do
        %AppCount.Ledgers.ChargeCode{
          code: sequence(:charge_code_name, &"abcd#{&1}"),
          name: "Test Charge Code",
          account: build(:account)
        }
      end

      def bill_factory do
        %AppCount.Ledgers.Charge{
          lease: build(:lease),
          amount: 100,
          status: "charge",
          bill_date: AppCount.current_date(),
          post_month: Timex.beginning_of_month(AppCount.current_date()),
          charge_code: build(:charge_code),
          customer_ledger: build(:customer_ledger)
        }
      end

      def customer_ledger_factory do
        %AppCount.Ledgers.CustomerLedger{
          name: "Some name",
          type: "tenant",
          property: build(:property)
        }
      end
    end
  end
end
