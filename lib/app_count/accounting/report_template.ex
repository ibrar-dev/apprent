defmodule AppCount.Accounting.ReportTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounting__report_templates" do
    field :name, :string
    field :groups, {:array, :map}
    field :is_balance, :boolean

    timestamps()
  end

  @doc false
  def changeset(report_template, attrs) do
    report_template
    |> cast(attrs, [:name, :groups, :is_balance])
    |> validate_required([:name, :groups])
    |> unique_constraint(:name)
  end
end
