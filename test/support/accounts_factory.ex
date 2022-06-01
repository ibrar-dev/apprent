defmodule AppCount.AccountsFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def user_account_factory do
        %AppCount.Accounts.Account{
          tenant: build(:tenant),
          encrypted_password: Bcrypt.hash_pwd_salt("password"),
          property: build(:property),
          username: sequence(:username, &"UserName#{&1}"),
          uuid: UUID.uuid4()
        }
      end

      def user_account_lock_factory do
        %AppCount.Accounts.Lock{
          account: build(:user_account),
          reason: "Whatever"
        }
      end

      def payment_source_factory do
        %AppCount.Accounts.PaymentSource{
          type: "cc",
          name: "William Smith",
          num1: "123455661234",
          num2: "123123123123",
          last_4: "1111",
          exp: "02/29",
          brand: "Visa",
          active: true,
          subtype: "",
          is_tokenized: true,
          original_network_transaction_id: "00000",
          original_auth_amount_in_cents: 1,
          account: build(:user_account)
        }
      end

      def bank_factory do
        %AppCount.Settings.Bank{
          name: "Bank of Fakeness",
          routing: "123456789"
        }
      end

      def autopay_factory do
        %AppCount.Accounts.Autopay{
          account: build(:user_account),
          payment_source: build(:payment_source),
          agreement_text: "This is the agreement text",
          agreement_accepted_at: Timex.now(),
          payer_ip_address: "127.0.0.1",
          active: true
        }
      end
    end
  end
end
