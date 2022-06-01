defmodule AppCount.Messaging.MailTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messaging__mail_templates" do
    field :subject, :string
    field :body, :string
    field :creator, :string
    field :history, {:array, :map}

    timestamps()
  end

  @doc false
  def changeset(mail_template, attrs) do
    mail_template
    |> cast(attrs, [:subject, :body, :creator, :history])
    |> validate_required([:subject, :body, :creator])
  end
end
