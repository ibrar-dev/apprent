defmodule AppCount.Properties.RecurringLetter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__recurring_letters" do
    field :active, :boolean
    field :last_run, :integer
    field :next_run, :integer
    field :notify, :boolean
    field :visible, :boolean
    field :name, :string
    embeds_one :schedule, AppCount.Jobs.Schedule, on_replace: :update
    embeds_one :resident_params, AppCount.Properties.ResidentParams, on_replace: :update
    belongs_to :letter_template, Module.concat(["AppCount.Properties.LetterTemplate"])
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])

    timestamps()
  end

  @doc false
  def changeset(recurring_letter, attrs) do
    recurring_letter
    |> cast(attrs, [
      :active,
      :last_run,
      :next_run,
      :letter_template_id,
      :notify,
      :visible,
      :admin_id,
      :name
    ])
    |> cast_resident_params(attrs)
    |> cast_schedule(attrs)
    |> validate_required([:active, :letter_template_id, :admin_id, :notify, :visible, :name])
  end

  defp cast_resident_params(cs, %{resident_params: _}), do: cast_embed(cs, :resident_params)
  defp cast_resident_params(cs, %{"resident_params" => _}), do: cast_embed(cs, :resident_params)
  defp cast_resident_params(cs, _), do: cs

  defp cast_schedule(cs, %{schedule: _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(cs, %{"schedule" => _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(%{data: %{schedule: s}} = cs, _) when not is_nil(s), do: cs
end
