defmodule AppCount.Maintenance.NoteRepoTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.NoteRepo
  alias AppCount.Core.ClientSchema

  @text_note "This is a text note"

  setup do
    prop_builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_tech()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_unit_category()
      |> PropBuilder.add_work_order_on_unit()
      |> PropBuilder.add_admin()

    [_prop_builder, tech, tenant, work_order, admin] =
      PropBuilder.get(prop_builder, [:tech, :tenant, :work_order, :admin])

    ~M[work_order, tech, tenant, admin]
  end

  describe "get_notes/2 :private" do
    test "works with tenant note", ~M[work_order, tenant] do
      NoteRepo.insert(%{
        order_id: work_order.id,
        tenant_id: tenant.id,
        text: @text_note
      })

      [note] = NoteRepo.get_notes(ClientSchema.new("dasmen", work_order.id), :private)

      assert note.tenant.first_name == tenant.first_name
    end

    test "works with tech note", ~M[work_order, tech] do
      NoteRepo.insert(%{
        order_id: work_order.id,
        tech_id: tech.id,
        text: @text_note
      })

      [note] = NoteRepo.get_notes(ClientSchema.new("dasmen", work_order.id), :private)

      assert note.tech.name == tech.name
    end

    test "works with admin note", ~M[work_order, admin] do
      NoteRepo.insert(%{
        order_id: work_order.id,
        admin_id: admin.id,
        text: @text_note
      })

      [note] = NoteRepo.get_notes(ClientSchema.new("dasmen", work_order.id), :private)

      assert note.admin.name == admin.name
    end
  end

  describe "get_notes/2 :public" do
    setup(%{work_order: work_order, admin: admin}) do
      NoteRepo.insert(%{
        order_id: work_order.id,
        admin_id: admin.id,
        text: @text_note,
        visible_to_resident: false
      })

      NoteRepo.insert(%{
        order_id: work_order.id,
        admin_id: admin.id,
        text: @text_note,
        visible_to_resident: true
      })

      ~M[work_order]
    end

    test "does not have private notes", ~M[work_order] do
      notes = NoteRepo.get_notes(ClientSchema.new("dasmen", work_order.id), :private)

      res = NoteRepo.get_notes(ClientSchema.new("dasmen", work_order.id), :public)

      assert length(notes) == 2
      assert length(res) == 1
    end
  end
end
