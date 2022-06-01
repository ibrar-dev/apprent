defmodule AppCount.Properties.DailyPaymentsEmailTest do
  use AppCount.DataCase
  use Bamboo.Test, shared: true
  alias AppCount.Admins.EmailSubscriptionsRepo, as: EmailsRepo
  alias AppCount.Tasks.Workers.DailyPaymentsEmail

  setup do
    [_builder, property, admin] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin_with_access()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_lease()
      |> PropBuilder.add_payment()
      |> PropBuilder.get([:property, :admin])

    ~M[property, admin]
  end

  test "perform/0", ~M[property, admin] do
    %{
      admin_id: admin.id,
      active: true,
      trigger: "daily_payments"
    }
    |> EmailsRepo.insert()

    DailyPaymentsEmail.perform()

    assert_email_delivered_with(
      subject: "[AppRent] Payments Report - 24 Hours",
      html_body: ~r/#{property.name}/m,
      to: [
        nil: admin.email
      ]
    )
  end
end
