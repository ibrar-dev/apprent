defmodule AppCount.Settings.CredentialSet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings__credential_sets" do
    field :provider, :string
    embeds_many :credentials, AppCount.Settings.Credential, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(credential_set, attrs) do
    credential_set
    |> cast(attrs, [:provider])
    |> cast_embed(:credentials)
    |> validate_required([:provider])
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(struct, opts) do
      %{
        id: struct.id,
        provider: struct.provider,
        credentials: Enum.map(struct.credentials, &Map.from_struct/1)
      }
      |> Jason.Encode.map(opts)
    end
  end
end
