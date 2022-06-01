defmodule AppCount.Maintenance.Tech do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.Tech
  alias AppCount.Maintenance.Assignment

  import AppCount.EctoTypes.Upload

  @derive {Jason.Encoder,
           only: [
             :name
           ]}

  schema "maintenance__techs" do
    # should email be uniq in the scope of property?
    field :email, :string
    # should name be uniq in the scope of property?
    field :name, :string
    field :type, :string, default: "Tech"
    field :description, :string, default: ""
    field :phone_number, :string
    field :pass_code, Ecto.UUID
    field :identifier, Ecto.UUID
    field :push_token, :string
    field :image, upload_type("appcount-maintenance:tech_images", "image", public: true)
    field :can_edit, :boolean, default: false
    field :active, :boolean, default: true
    field :require_image, :boolean, default: false
    field(:aggregate, :boolean, virtual: true, default: false)
    has_many :jobs, AppCount.Maintenance.Job
    has_many :skills, AppCount.Maintenance.Skill
    has_many :assignments, AppCount.Maintenance.Assignment
    has_many :timecards, AppCount.Maintenance.Timecard
    has_many :paid_times, AppCount.Maintenance.PaidTime

    many_to_many :categories, AppCount.Maintenance.Category,
      join_through: AppCount.Maintenance.Skill

    field :average_completion_time, :float, virtual: true
    field :metrics, :map, virtual: true
    field :top_skills, {:array, :map}, virtual: true

    timestamps()
  end

  @doc false
  def changeset(%Tech{} = tech, attrs) do
    tech
    |> cast(attrs, [
      :name,
      :email,
      :phone_number,
      :pass_code,
      :type,
      :description,
      :push_token,
      :image,
      :can_edit,
      :active,
      :require_image
    ])
    |> validate_required([:name, :email, :phone_number, :type, :can_edit])
  end

  def pending_count(%Tech{} = tech) do
    tech.assignments
    |> Enum.filter(fn assignment -> Assignment.pending?(assignment) end)
    |> length()
  end
end
