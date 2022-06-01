defmodule AppCount.SettingsFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def move_out_reason_factory do
        %AppCount.Settings.MoveOutReason{
          name: "Something"
        }
      end

      def credential_set_factory do
        %AppCount.Settings.CredentialSet{
          provider: "APIs R Us",
          credentials: [
            %{name: "username", value: "user name"},
            %{name: "password", value: "password"},
            %{name: "id", value: "1234567890"}
          ]
        }
      end
    end
  end
end
