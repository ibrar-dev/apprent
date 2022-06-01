defmodule AppCount.Tasks.Workers.RecurringLetters do
  import Ecto.Query
  alias AppCount.Properties.RecurringLetter
  alias AppCount.Jobs.Scheduler
  alias AppCount.Repo
  alias AppCount.Properties.Utils.LetterTemplates
  alias AppCount.Properties.Utils.RecurringLetters

  use AppCount.Tasks.Worker, "Recurring Property letters"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    now =
      AppCount.current_time()
      |> Timex.to_unix()

    from(
      r in RecurringLetter,
      where: r.next_run <= ^now and r.active == true
    )
    |> Repo.all(prefix: schema)
    |> Enum.each(&process/1)
  end

  def process(%RecurringLetter{
        id: id,
        admin_id: admin_id,
        letter_template_id: template_id,
        notify: notify,
        visible: visible,
        schedule: schedule,
        next_run: next_run
      }) do
    tenant_ids = AppCount.Properties.Utils.ResidentParams.get_residents(id)
    admin = Repo.get(AppCount.Admins.Admin, admin_id)

    params = %{
      "template_id" => template_id,
      "tenant_ids" => tenant_ids,
      "visible" => visible,
      "notify" => notify
    }

    # FIX_DEPS but how?
    module = Module.concat(["AppCountWeb.LetterPreviewer"])
    generate_binary_fn = &module.generate_binary/1
    LetterTemplates.generate_letters(admin, params, generate_binary_fn)

    case Scheduler.next_ts(schedule) do
      nil ->
        RecurringLetters.delete_recurring_letter(id)

      ts ->
        RecurringLetters.update_recurring_letter(id, %{
          next_run: ts,
          last_run: next_run
        })
    end
  end
end
