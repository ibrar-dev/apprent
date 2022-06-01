defmodule AppCount.Properties.Utils.RecurringLetters do
  import Ecto.Query
  alias AppCount.Properties.RecurringLetter
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema
  alias AppCount.Tasks.Workers.RecurringLetters

  def list_recurring_letters(admin, property_id) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      r in RecurringLetter,
      join: l in assoc(r, :letter_template),
      where: l.property_id in ^property_ids and l.property_id == ^property_id,
      select: %{
        id: r.id,
        letter_template_id: r.letter_template_id,
        active: r.active,
        last_run: r.last_run,
        next_run: r.next_run,
        notify: r.notify,
        visible: r.visible,
        schedule: type(r.schedule, :map),
        resident_params: type(r.resident_params, :map),
        name: r.name,
        admin_id: r.admin_id
      }
    )
    |> Repo.all()
  end

  def create_recurring_letter(params) do
    %RecurringLetter{}
    |> RecurringLetter.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, l} -> schedule_next(l)
      e -> e
    end
  end

  def update_recurring_letter(id, params) do
    Repo.get(RecurringLetter, id)
    |> RecurringLetter.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, l} -> schedule_next(l)
      e -> e
    end
  end

  def run_recurring_letters_early(id) do
    Repo.get(RecurringLetter, id)
    |> RecurringLetters.process()
  end

  def delete_recurring_letter(id) do
    Repo.get(RecurringLetter, id)
    |> RecurringLetter.changeset(%{active: false})
    |> Repo.update()
  end

  defp schedule_next(letter) do
    letter
    |> RecurringLetter.changeset(%{next_run: AppCount.Jobs.Scheduler.next_ts(letter.schedule)})
    |> Repo.update()
  end
end
