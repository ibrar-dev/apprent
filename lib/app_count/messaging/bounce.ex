defmodule AppCount.Messaging.Bounce do
  use Ecto.Schema
  import Ecto.Changeset

  # Email addresses that have been bounced for whatever reason and we cannot send emails to
  schema "messaging__bounces" do
    field :target, :string

    timestamps()
  end

  @doc false
  def changeset(bounce, attrs) do
    bounce
    |> cast(attrs, [:target])
    |> validate_required([:target])
  end

  def valid_email?(email) when is_binary(email) do
    case Regex.run(~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i, email) do
      nil -> false
      _ -> true
    end
  end

  # When the input is not binary for some reason.
  def valid_email?(_), do: false
end
