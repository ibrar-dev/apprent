defmodule AppCount.Maintenance.Assignment do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.Assignment

  schema "maintenance__assignments" do
    belongs_to :admin, AppCount.Admins.Admin
    belongs_to :order, AppCount.Maintenance.Order
    belongs_to :payee, AppCount.Accounting.Payee
    belongs_to :tech, AppCount.Maintenance.Tech

    field :callback_info, :map
    field :completed_at, :naive_datetime
    field :confirmed_at, :naive_datetime
    field :email, {:array, :map}, default: []
    field :history, {:array, :map}
    field :materials, {:array, :map}, default: []
    field :rating, :integer
    field :resident_comment, :string
    # status: withdrawn, in_progress,  callback,  on_hold, pending
    field :status, :string
    field :tech_comments, :string
    field :tenant_comment, :string

    timestamps()
  end

  def pending?(%Assignment{status: "pending"}), do: true
  def pending?(%Assignment{}), do: false

  def completed?(%Assignment{completed_at: nil}), do: false
  def completed?(%Assignment{}), do: true

  def callback?(%Assignment{status: "callback"}), do: true
  def callback?(%Assignment{}), do: false

  def rating_changeset(%Assignment{} = assignment, attrs \\ %{}) do
    assignment
    |> cast(attrs, [:rating, :tenant_comment])
    |> validate_required(:rating)
    |> validate_inclusion(:rating, [1, 2, 3, 4, 5])
  end

  def completion_hours(%Assignment{completed_at: nil}) do
    :incomplete
  end

  def completion_hours(%Assignment{inserted_at: nil}) do
    :incomplete
  end

  def completion_hours(%Assignment{
        inserted_at: %NaiveDateTime{} = inserted_at,
        completed_at: %NaiveDateTime{} = completed_at
      }) do
    hour_in_seconds = 60 * 60
    seconds_diff = NaiveDateTime.diff(completed_at, inserted_at)
    Integer.floor_div(seconds_diff, hour_in_seconds)
  end

  def changeset(%Assignment{} = assignment, attrs) do
    assignment
    |> cast(
      attrs,
      [
        :admin_id,
        :callback_info,
        :completed_at,
        :confirmed_at,
        :email,
        :history,
        :materials,
        :order_id,
        :payee_id,
        :rating,
        :resident_comment,
        :status,
        :tech_comments,
        :tech_id,
        :tenant_comment
      ]
    )
    |> validate_required([:status, :order_id])
    |> check_constraint(:tech_id, name: :must_have_assigner)
  end
end
