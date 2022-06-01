defmodule AppCount.Properties.RecurringLettersTest do
  use AppCount.DataCase
  alias AppCount.Properties
  alias AppCount.Properties.Utils.RecurringLetters
  @moduletag :properties_recurring_letters

  test "run_recurring_letters_early" do
    {:ok, result} = RecurringLetters.run_recurring_letters_early(insert(:recurring_letter).id)
    assert result
  end

  test "recurring letters CRUD" do
    template = insert(:letter_template)
    admin = admin_with_access([template.property_id])

    %{
      "admin_id" => admin.id,
      "letter_template_id" => template.id,
      "name" => "Recurring Letter Random",
      "visible" => true,
      "active" => false,
      "notify" => true,
      "schedule" => %{"hour" => [0]}
    }
    |> RecurringLetters.create_recurring_letter()

    letter =
      Repo.get_by(Properties.RecurringLetter,
        name: "Recurring Letter Random",
        letter_template_id: template.id
      )

    assert letter

    RecurringLetters.update_recurring_letter(letter.id, %{"active" => true})

    assert Repo.get(Properties.RecurringLetter, letter.id).active

    [result] = RecurringLetters.list_recurring_letters(admin, template.property_id)

    assert result.id == letter.id

    RecurringLetters.delete_recurring_letter(letter.id)

    refute Repo.get(Properties.RecurringLetter, letter.id).active
  end
end
