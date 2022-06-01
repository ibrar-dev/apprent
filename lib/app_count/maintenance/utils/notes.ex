defmodule AppCount.Maintenance.Utils.Notes do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Note
  alias AppCount.Core.ClientSchema

  def create_note(%ClientSchema{
        name: client_schema,
        attrs: %{"image" => %{path: path, filename: filename}} = attrs
      }) do
    %Note{}
    |> Note.changeset(Map.put(attrs, "image", filename))
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, note} -> upload_note_image(note.id, path, filename)
      {:error, e} -> {:error, e}
    end
  end

  def create_note(%ClientSchema{
        name: client_schema,
        attrs: %{"image" => %{"data" => file_data}} = attrs
      }) do
    #    binary = Base.decode64!(file_data)
    binary =
      case Base.decode64(file_data) do
        {:ok, data} -> data
        _ -> :base64.decode(file_data)
      end

    filename =
      UUID.uuid4()
      |> String.upcase()

    %Note{}
    |> Note.changeset(Map.put(attrs, "image", "#{filename}.jpg"))
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, note} -> put_image(note.id, "#{filename}.jpg", binary)
      {:error, e} -> {:error, e}
    end
  end

  def create_note(%ClientSchema{name: client_schema, attrs: %{"attachment" => _} = params}) do
    %Note{}
    |> Note.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  # Image note -- process the attachment and roll with it
  def create_note(%ClientSchema{name: client_schema, attrs: %{image: image, text: _} = attrs})
      when not is_nil(image) do
    new_attrs = Map.replace!(attrs, :image, image.filename)

    note =
      %Note{}
      |> Note.changeset(new_attrs)
      |> Repo.insert!(prefix: client_schema)

    file_binary = File.read!(image.path)
    put_image(note.id, image.filename, file_binary)
  end

  # Text Note -- let's make a note record and send the email, mentions and all
  def create_note(%ClientSchema{name: client_schema, attrs: %{text: text} = attrs} = schema)
      when not is_nil(text) do
    note =
      %Note{}
      |> Note.changeset(attrs)
      |> Repo.insert(prefix: client_schema)

    case note do
      {:ok, _n} ->
        # send emails if any mentions
        send_notes(schema)
        note

      _ ->
        # Something went wrong - return the note, but don't send
        note
    end
  end

  # exit condition -- we don't need to do anything
  def create_note(%ClientSchema{attrs: %{text: text, image: image}})
      when is_nil(text) and is_nil(image) do
    nil
  end

  def create_note(%ClientSchema{name: client_schema, attrs: attrs}) do
    atomized =
      Enum.into(
        attrs,
        %{},
        fn
          {k, v} when is_binary(k) -> {String.to_atom(k), v}
          {k, v} -> {k, v}
        end
      )

    mentions =
      atomized.mentions
      |> Enum.map(fn m ->
        Enum.into(m, %{}, fn {k, v} -> {String.to_atom(k), v} end)
      end)

    # Create the "Image" version of the note
    attrs =
      Map.put(atomized, :text, nil)
      |> Map.put(:mentions, [])

    create_note(%ClientSchema{name: client_schema, attrs: attrs})

    # Create the text version of the note
    attrs =
      Map.put(atomized, :image, nil)
      |> Map.put(:mentions, mentions)

    create_note(%ClientSchema{name: client_schema, attrs: attrs})
  end

  def fetch_order(%ClientSchema{name: client_schema, attrs: order_id}) do
    order =
      from(o in AppCount.Maintenance.Order,
        where: o.id == ^order_id,
        preload: [property: [:logo], category: []],
        limit: 1
      )
      |> Repo.one(prefix: client_schema)

    if order do
      {:ok, order}
    else
      {:error, "No Order"}
    end
  end

  def fetch_admin(%ClientSchema{name: client_schema, attrs: id}) do
    admin = Repo.get(AppCount.Admins.Admin, id, prefix: client_schema)

    if admin do
      {:ok, admin}
    else
      {:error, "No admin"}
    end
  end

  # TO DO: bring this up to the Notes Controller to break the compile cycle loop.
  def fetch_property(client_schema, id) do
    property = AppCount.Properties.get_property(ClientSchema.new(client_schema, id))

    if property do
      {:ok, property}
    else
      {:error, "No property"}
    end
  end

  # Send notes to all mentions from an admin, assuming mentions exist
  def send_notes(%ClientSchema{name: client_schema, attrs: %{mentions: mentions} = attrs})
      when length(mentions) > 0 do
    %{admin_id: admin_id, order_id: order_id, text: text} = attrs

    with {:ok, admin} <- fetch_admin(%ClientSchema{name: client_schema, attrs: admin_id}),
         {:ok, order} <- fetch_order(%ClientSchema{name: client_schema, attrs: order_id}),
         %{property_id: property_id, category: %{name: category_name}, ticket: ticket} <- order,
         {:ok, property} <- fetch_property(client_schema, property_id) do
      mentions
      |> Enum.each(fn m ->
        name = constructed_name(m.name)
        text = constructed_text(text)

        send_note(
          m.email,
          name,
          admin.name,
          ticket,
          category_name,
          text,
          property,
          constructed_work_order_link(m, order.id)
        )
      end)
    end
  end

  # No mentions, so we don't need to do anything
  def send_notes(_) do
    nil
  end

  # name comes in as either:
  # + Ada Lovelace
  # + Ada Lovelace (Resident)
  #
  # In both cases, we just want to return "Ada Lovelace"
  def constructed_name(name) do
    String.replace(name, ~r{\s*\(Resident\)}, "")
  end

  # If we mention the resident, we see `(Resident)` right in the note body. We
  # want that to not be in the note body.
  def constructed_text(txt) do
    String.replace(txt, ~r{\s*\(Resident\)\s*}, " ")
  end

  def constructed_work_order_link(mention, order_id) do
    # If the recipient is an admin user, rather than the resident
    if mention.id != 0 do
      root = AppCount.UrlHelper.admin_url()
      "#{root}/orders/#{order_id}"
    else
      # TODO: Point to resident portal once we have some assurance that all
      #   users have accounts
      ""
    end
  end

  def send_note(
        to,
        to_name,
        author_name,
        work_order_id,
        category_description,
        note,
        property,
        link
      ) do
    AppCountCom.WorkOrders.new_note_on_work_order(
      to,
      to_name,
      work_order_id,
      category_description,
      note,
      author_name,
      property,
      link
    )
  end

  def delete_note(id) do
    Repo.get(Note, id)
    |> Repo.delete()
  end

  def create_tech_note(
        %ClientSchema{name: client_schema, attrs: assignment_id},
        %{"attachment" => _} = params
      ) do
    assignment = Repo.get(Assignment, assignment_id, prefix: client_schema)

    attrs =
      %{
        "text" => nil,
        "image" => nil,
        "mentions" => [],
        "tech_id" => assignment.tech_id,
        "order_id" => assignment.order_id
      }
      |> Map.merge(params)

    ClientSchema.new(client_schema, attrs)
    |> create_note
  end

  def create_tech_note(%ClientSchema{name: client_schema, attrs: assignment_id}, message) do
    assignment = Repo.get(Assignment, assignment_id, prefix: client_schema)

    attrs =
      %{
        "text" => nil,
        "image" => nil,
        "mentions" => [],
        "tech_id" => assignment.tech_id,
        "order_id" => assignment.order_id
      }
      |> Map.merge(message["note"])

    create_note(%ClientSchema{name: client_schema, attrs: attrs})
  end

  def put_image(id, filename, file_binary) do
    env = AppCount.Config.env()

    AppCount.Utils.put_public_s3(
      "appcount-maintenance:notes/#{env}/#{id}/#{filename}",
      file_binary
    )
  end

  defp upload_note_image(id, path, filename) do
    {:ok, file_binary} = File.read(path)
    put_image(id, filename, file_binary)
  end

  def export_notes_with_id() do
    file = File.open!("categories_csv/012819.csv", [:write, :utf8])

    from(
      n in Note,
      join: o in assoc(n, :order),
      join: c in assoc(o, :category),
      join: p in assoc(c, :parent),
      where: not is_nil(n.text) and c.parent_id != 3196,
      select: %{
        text: n.text,
        category_id: o.category_id
      }
    )
    |> Repo.all()
    |> CSV.encode(headers: [:text, :category_id])
    |> Enum.each(&IO.write(file, &1))
  end
end
