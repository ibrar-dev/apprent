defmodule AppCount.RentApply.Utils.Processing do
  alias AppCount.Repo
  alias AppCount.Properties
  alias AppCount.Properties.Occupancy
  alias AppCount.Properties.Charge
  alias AppCount.Tenants.Tenant
  alias AppCount.Leases.Lease
  alias AppCount.Leases.Form
  alias AppCount.RentApply.RentApplication
  alias AppCount.RentApply.Person
  alias AppCount.Tenants.Utils.CreateTenant
  alias Ecto.Multi
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def preapprove(%RentApplication{} = app, approval_params) do
    case validate_params(app.id, approval_params) do
      true ->
        params_with_rent = add_rent(approval_params)

        app
        |> RentApplication.changeset(%{status: "preapproved", approval_params: params_with_rent})
        |> Repo.update()
        |> case do
          {:ok, application} ->
            # Does not do anything
            {:ok, application}

          {:error, [{field, {msg, _}}]} ->
            {:error, "#{field} #{msg}"}
        end

      {:error, [{field, {msg, _}}]} ->
        {:error, "#{field} #{msg}"}
    end
  end

  def approve(%RentApplication{} = app) do
    app
    |> RentApplication.changeset(%{status: "approved", approval_params: %{}})
    |> Repo.update!()

    app.approval_params
    |> Map.from_struct()
    |> Map.merge(%{application_id: app.id})
    |> CreateTenant.create_tenant(application_id: app.id)
  end

  def create_tenant(app) do
    app.approval_params
    |> Map.from_struct()
    |> Map.merge(%{application_id: app.id})
    |> CreateTenant.create_tenant(application_id: app.id)
    |> case do
      {:ok, app} ->
        {:ok, app}

      {:error, _, %{errors: [{f, {error, _}}]}, _} ->
        field =
          String.replace("#{f}", ~r/_id/, "")
          |> String.capitalize()

        {:error, "#{field} #{error}"}
    end
  end

  def bypass_approve(%RentApplication{} = app, _bluemoon_info) do
    Multi.new()
    |> Multi.run(
      :bypass_approval,
      fn _repo, _cs ->
        RentApplication.changeset(app, %{status: "approved"})
        |> Repo.update()
      end
    )
    |> Multi.run(:create_tenant, fn _repo, _cs -> create_tenant(app) end)
    #    |> Multi.run(
    #         :create_bluemoon_lease,
    #         fn (_repo, cs) ->
    #           AppCount.Leases.create_form_from_bluemoon(
    #             Map.merge(bluemoon_info, %{"lease_id" => cs.create_tenant.lease.id})
    #           )
    #         end
    #       )
    |> Repo.transaction()
    |> case do
      {:ok, r} -> r
      {:error, _, e, _} -> {:error, "#{e}"}
    end
  end

  def decline(%RentApplication{} = app) do
    app
    |> RentApplication.changeset(%{status: "declined", approval_params: %{}})
    |> Repo.update()
  end

  def conditional(%RentApplication{} = app) do
    app
    |> RentApplication.changeset(%{status: "conditional"})
    |> Repo.update()
  end

  def application_signed(app_id) do
    {:ok, app} =
      Repo.get(RentApplication, app_id)
      |> RentApplication.changeset(%{status: "signed"})
      |> Repo.update()

    form_params =
      from(
        f in Form,
        where: f.application_id == ^app.id,
        select: %{
          bluemoon_lease_id: f.form_id,
          bluemoon_signature_id: f.signature_id,
          document_id: f.document_id
        }
      )
      |> Repo.one()

    app.approval_params
    |> Map.from_struct()
    |> Map.merge(form_params)
    |> CreateTenant.create_tenant(application_id: app.id)

    notify_applicant(app)
  end

  defp validate_params(app_id, approval_params) do
    with nil <-
           from(
             r in RentApplication,
             where:
               fragment("(? -> 'unit_id') = ?", r.approval_params, ^approval_params["unit_id"]),
             where: r.id != ^app_id,
             where: r.status != "declined" or r.status != "signed"
           )
           |> Repo.one(),
         {:ok, %{tenants: t, lease: l}} <- CreateTenant.create_tenant(approval_params) do
      Enum.each(t, &Repo.delete/1)
      Repo.delete(l)
      Enum.each([Tenant, Lease, Occupancy, Charge], &Repo.reset_id/1)
      true
    else
      %RentApplication{} ->
        {:error, [{:unit, {"is already reserved for another application", []}}]}

      {:error, _, cs, _} ->
        {:error, cs.errors}
    end
  end

  defp notify_applicant(application) do
    property = Properties.get_property(ClientSchema.new("dasmen", application.property_id))

    from(
      p in Person,
      where: p.application_id == ^application.id and p.status == "Lease Holder",
      select: p.email
    )
    |> Repo.all()
    |> Enum.each(fn email ->
      AppCount.Core.Tasker.start(fn ->
        AppCountCom.Applications.application_approved(
          email,
          Map.put(application, :property, property)
        )
      end)
    end)
  end

  defp add_rent(%{"rent" => rent_amount, "charges" => charges} = params) do
    rent_account_id = Repo.get_by(AppCount.Accounting.Account, name: "Rent").id

    added =
      Enum.concat(
        charges,
        [
          %{"account_id" => rent_account_id, "name" => "Rent", "amount" => rent_amount}
        ]
      )

    Map.put(params, "charges", added)
  end
end
