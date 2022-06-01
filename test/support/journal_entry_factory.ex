# defmodule AppCount.JournalEntryFactory do
#  use ExMachina.Ecto, repo: AppCount.Repo
#  defmacro __using__(_opts) do
#    quote do
#
#      def journal_entry_factory do
#        property = insert(:property)
#        account = insert(:account)
#        page = insert(:page)
#        %AppCount.Accounting.JournalEntry{
#          property: build(:property),
#          account: build(:account),
#          amount: 100,
#          page: build(:journal_page)
#        }
#      end
#
#      def journal_page_factory do
#        %AppCount.Accounting.JournalPage{
#          name: sequence(:name, &"JournalPage #{&1}"),
#          date: AppCount.current_date(),
#          cash: true,
#          accrual: true
#        }
#      end
#
#    def account_factory do
#      %AppCount.Accounting.Account{
#        name: sequence(:name, &"Accountz #{&1}")
#      }
#    end
#
#      def property_factory do
#        %AppCount.Properties.Property{
#          name: "Test Property",
#          code: sequence(:code, &"test-#{&1}"),
#          address: %{
#            zip: "28205",
#            street: "3317 Magnolia Hill Dr",
#            state: "NC",
#            city: "Charlotte"
#          },
#          terms: "These are my terms, take 'em or leave 'em",
#          setting: build(:setting),
#          social: %{}
#        }
#      end
#
#
#
#  end
#  end
#  end
