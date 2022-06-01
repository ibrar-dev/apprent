defmodule AppCount.RentApply.Utils.Screening do
  alias AppCount.Repo
  alias AppCount.RentApply.RentApplication
  alias AppCount.Leases.Utils.Screenings
  import Ecto.Query
  use AppCount.Decimal

  # UNTESTED
  def screen_application(application_id, rent, instant_screen \\ false, schema) do
    app =
      from(
        a in RentApplication,
        join: p in assoc(a, :persons),
        join: h in assoc(a, :histories),
        left_join: e in assoc(p, :employments),
        on: e.person_id == p.id and e.current == true,
        left_join: i in assoc(a, :income),
        left_join: s in assoc(p, :screening),
        preload: [
          persons: {
            p,
            screening: s, employments: e
          },
          histories: h,
          income: i
        ],
        where: a.id == ^application_id
      )
      |> Repo.one(prefix: schema)

    {:ok, Enum.reduce(app.persons, nil, &screen(&1, app, rent, &2, instant_screen, schema))}
  end

  def screen(
        %{status: "Lease Holder"} = person,
        application,
        rent,
        order_ids,
        _instant_screen,
        schema
      ) do
    name_parts = String.split(person.full_name, " ")

    %{
      first_name: List.first(name_parts),
      last_name: List.last(name_parts),
      email: person.email,
      phone: person.home_phone || person.cell_phone || person.work_phone,
      ssn: person.ssn,
      dob: "#{person.dob}",
      rent: rent,
      income: income(person, application, is_nil(order_ids)),
      linked_orders: order_ids,
      person_id: person.id,
      property_id: application.property_id
    }
    |> Map.merge(residency_fields(application))
    |> Screenings.create_screening(true, schema)
    |> case do
      {:ok, screening} -> (order_ids || []) ++ [screening.order_id]
      e -> e
    end
  end

  def screen(_, _, _, order_ids, _instant_screen), do: order_ids

  def get_status(application_id) do
    from(
      a in RentApplication,
      join: p in assoc(a, :persons),
      join: s in assoc(p, :screening),
      select: s.id,
      where: a.id == ^application_id
    )
    |> Repo.all()
    |> Enum.map(&Screenings.get_screening_status/1)
  end

  defp income(person, application, include_income) do
    salary =
      person.employments
      |> Enum.reduce(
        0,
        fn emp, sum ->
          if emp.person_id == person.id do
            sum + emp.salary
          else
            sum
          end
        end
      )

    if include_income do
      (application.income && application.income.salary) + salary
    else
      salary
    end
  end

  defp residency_fields(application) do
    Enum.reduce_while(
      application.histories,
      nil,
      fn
        %{current: true} = h, _ -> {:halt, Map.take(h, [:street, :city, :state, :zip])}
        _, _ -> {:cont, nil}
      end
    )
  end
end
