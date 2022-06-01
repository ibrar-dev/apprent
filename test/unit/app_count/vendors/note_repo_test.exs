defmodule AppCount.Vendors.NoteRepoTest do
  use AppCount.DataCase
  alias AppCount.Vendors.NoteRepo

  @text_note "This is a text note"

  setup do
    prop_builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_tech()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_vendor()
      |> PropBuilder.add_vendor_category()
      |> PropBuilder.add_vendor_work_order()
      |> PropBuilder.add_admin()

    [_prop_builder, tech, tenant, vendor_work_order, admin] =
      PropBuilder.get(prop_builder, [:tech, :tenant, :vendor_work_order, :admin])

    ~M[vendor_work_order, tech, tenant, admin]
  end

  describe "get_notes/1" do
    test "works with tenant note", ~M[vendor_work_order, tenant] do
      NoteRepo.insert(%{
        order_id: vendor_work_order.id,
        tenant_id: tenant.id,
        text: @text_note
      })

      [note] = NoteRepo.get_notes(vendor_work_order.id)

      assert note.tenant.first_name == tenant.first_name
    end

    test "works with tech note", ~M[vendor_work_order, tech] do
      NoteRepo.insert(%{
        order_id: vendor_work_order.id,
        tech_id: tech.id,
        text: @text_note
      })

      [note] = NoteRepo.get_notes(vendor_work_order.id)

      assert note.tech.name == tech.name
    end

    test "works with admin note", ~M[vendor_work_order, admin] do
      NoteRepo.insert(%{
        order_id: vendor_work_order.id,
        admin_id: admin.id,
        text: @text_note
      })

      [note] = NoteRepo.get_notes(vendor_work_order.id)

      assert note.admin.name == admin.name
    end
  end
end
