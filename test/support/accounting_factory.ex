defmodule AppCount.AccountingFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def receipt_factory do
        %AppCount.Accounting.Receipt{
          amount: 50,
          payment: build(:payment),
          charge: build(:payment)
        }
      end

      def bank_account_factory do
        %AppCount.Accounting.BankAccount{
          name: "Some Bank",
          account_number: "123468900",
          routing_number: "29562452",
          bank_name: "Wells Fake-o",
          account: build(:account),
          address: %{}
        }
      end

      def account_factory do
        %AppCount.Accounting.Account{
          name: sequence(:name, &"Account #{&1}")
        }
      end

      def register_factory do
        %AppCount.Accounting.Register{
          property: build(:property),
          account: build(:account)
        }
      end

      def payee_factory do
        %AppCount.Accounting.Payee{
          name: sequence(:name, &"Payee #{&1}")
        }
      end

      def invoice_factory do
        %AppCount.Accounting.Invoice{
          payable_account: build(:account),
          post_month: Timex.beginning_of_month(AppCount.current_date()),
          date: AppCount.current_date(),
          due_date: Timex.shift(AppCount.current_date(), months: 1),
          payee: build(:payee),
          number: sequence(:number, &"12345-#{&1}"),
          amount: 1000
        }
      end

      def invoicing_factory do
        %AppCount.Accounting.Invoicing{
          invoice: build(:invoice),
          property: build(:property),
          account: build(:account),
          amount: 100
        }
      end

      def invoice_payment_factory do
        %AppCount.Accounting.InvoicePayment{
          invoicing: build(:invoicing),
          post_month: Timex.beginning_of_month(AppCount.current_date()),
          amount: 100,
          account: build(:account)
        }
      end

      def journal_page_factory do
        %AppCount.Accounting.JournalPage{
          name: sequence(:name, &"JournalPage #{&1}"),
          date: AppCount.current_date(),
          post_month: Timex.beginning_of_month(AppCount.current_date()),
          cash: true,
          accrual: true
        }
      end

      def journal_entry_factory do
        %AppCount.Accounting.JournalEntry{
          property: build(:property),
          account: build(:account),
          amount: 100,
          page: build(:journal_page)
        }
      end

      def accounting_entity_factory do
        %AppCount.Accounting.Entity{
          property: build(:property),
          bank_account: build(:bank_account)
        }
      end

      def check_factory do
        %AppCount.Accounting.Check{
          number: "1234567890",
          amount_lang:
            "ONE BILLION TWO HUNDRED THIRTY FOUR MILLION FIVE HUNDRED SIXTY SEVEN THOUSAND EIGHT HUNDRED NINETY",
          amount: 123,
          date: %Date{
            year: 2018,
            month: 5,
            day: 15
          },
          payee: build(:payee),
          bank_account: build(:bank_account)
        }
      end

      def account_category_factory do
        %AppCount.Accounting.Category{
          num: 10_000_000,
          name: "Cat1",
          max: 19_999_999
        }
      end
    end
  end
end
