defmodule AppCount.Admins.EmailSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    The thought is when getting admins to email we check to see if they are subscribed to whatever is triggering the email.
    For example: new application, rather than sending out the email to ALL admins that have the property,
    first check to get only admins that have the trigger new_application.
    This system will require updating all places that get admins to email, but thats ok.
  """

  schema "admins__email_subscriptions" do
    field :trigger, :string
    field :active, :boolean, default: true
    belongs_to :admin, AppCount.Admins.Admin

    timestamps()
  end

  @doc false
  def changeset(email_subscription, attrs) do
    email_subscription
    |> cast(attrs, [:trigger, :active, :admin_id])
    |> validate_required([:trigger, :active, :admin_id])
    |> unique_constraint(
      :trigger,
      name: :admins__email_subscriptions_admin_id_trigger_index,
      message: "admin already subscribed"
    )
  end
end
