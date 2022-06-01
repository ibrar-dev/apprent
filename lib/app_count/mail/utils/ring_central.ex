defmodule AppCount.Mail.Utils.RingCentral do
  alias AppCount.Repo
  alias AppCount.Prospects
  alias AppCount.Maintenance
  alias AppCount.Properties.PhoneLine
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def process_ring_central(message) do
    %{"subject" => subject, "to" => [to]} = message["mail"]["commonHeaders"]
    [_, name, from_number] = Regex.run(~r"New .* from (.*) (\(\d\d\d\) \d\d\d-\d\d\d\d)", subject)

    from(p in PhoneLine, where: p.number == ^find_to(message["content"]), select: p.property_id)
    |> Repo.one()
    |> case do
      nil ->
        nil

      property_id ->
        String.split(to, "@")
        |> List.first()
        |> do_insert(property_id, name, from_number)
    end
  end

  defp find_to(content) do
    {:ok, document} =
      Base.decode64!(content)
      |> Floki.parse_document()

    line =
      document
      |> Floki.find(".lptext")
      |> Enum.at(2)
      |> elem(2)
      |> hd

    ~r"\(\d\d\d\) \d\d\d-\d\d\d\d"
    |> Regex.run(line)
    |> hd
  end

  defp do_insert("leasing", property_id, name, from_number) do
    Prospects.create_prospect(%{
      name: name,
      phone: from_number,
      property_id: property_id,
      notes: "Missed Call",
      contact_date: AppCount.current_date(),
      contact_type: "Phone"
    })
  end

  defp do_insert("maintenance", property_id, name, from_number) do
    # TODO:SCHEMA remove the static
    Maintenance.create_order(
      ClientSchema.new(
        "dasmen",
        %{
          property_id: property_id,
          created_by: "Missed Call from #{name} #{from_number}",
          category_id: order_category().id,
          status: "unassigned"
        }
      )
    )
  end

  defp order_category() do
    # TODO:SCHEMA remove this later
    schema = "dasmen"

    case Repo.nil_safe_get_by(Maintenance.Category, name: "General", parent_id: nil) do
      nil ->
        Maintenance.create_category({%{name: "General"}, schema})
        order_category()

      category ->
        case Repo.get_by(Maintenance.Category,
               name: "Other (Describe in Notes)",
               parent_id: category.id
             ) do
          nil ->
            Maintenance.create_category(
              {%{
                 "name" => "Other (Describe in Notes)",
                 "path" => [category.id]
               }, schema}
            )

            order_category()

          c ->
            c
        end
    end
  end
end
