defmodule AppCountWeb.API.ApplicationView do
  use AppCountWeb, :view

  @person_props [:id, :full_name, :status, :email, :home_phone, :work_phone, :cell_phone]

  def render("index.json", %{applications: applications}) do
    render_many(applications, __MODULE__, "application.json")
  end

  def render("application.json", %{application: application}) do
    %{
      id: application.id,
      persons: Enum.map(application.persons, &Map.take(&1, @person_props)),
      status: application.status,
      property: %{
        name: application.property.name,
        id: application.property.id
      },
      approval_params: application.approval_params,
      payment: Map.take(application.payment || %{}, [:transaction_id, :amount]),
      admin_payment: Map.take(application.admin_payment || %{}, [:transaction_id, :amount]),
      documents: Enum.map(application.documents, &Map.take(&1, [:id, :type])),
      inserted_at: application.inserted_at
    }
  end
end
