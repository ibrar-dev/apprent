defmodule AppCount.Approvals.ApprovalRepoTest do
  use AppCount.DataCase
  import Mock
  alias AppCount.Approvals.ApprovalRepo
  @moduletag :approval_repo

  setup do
    property =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.get_requirement(:property)

    admin = Factory.admin_with_access([property.id])
    approval_attrs = approval_attrs(property, admin)

    ~M[property, admin, approval_attrs]
  end

  def approval_attrs(property, admin) do
    %{
      property_id: property.id,
      admin_id: admin.id,
      num: "3",
      type: "type",
      params: %{}
    }
  end

  test "insert from approval_struct", ~M[approval_attrs] do
    original_count = ApprovalRepo.count()
    # When
    ApprovalRepo.insert(approval_attrs)

    current_count = ApprovalRepo.count()
    assert current_count == original_count + 1
  end

  test "insert from approval_attrs", ~M[approval_attrs] do
    original_count = ApprovalRepo.count()

    # When
    ApprovalRepo.insert(approval_attrs)

    current_count = ApprovalRepo.count()
    assert current_count == original_count + 1
  end

  describe "exists in DB" do
    setup context do
      {:ok, approval} = ApprovalRepo.insert(context.approval_attrs)

      ~M[approval]
    end

    test "get ", ~M[approval] do
      assert ApprovalRepo.get(approval.id)
    end

    test "get_aggregate ", ~M[approval] do
      # When
      found_approval = ApprovalRepo.get_aggregate(approval.id)
      # Then
      assert Ecto.assoc_loaded?(found_approval.admin)
      assert Ecto.assoc_loaded?(found_approval.property)
      assert Ecto.assoc_loaded?(found_approval.attachments)
      assert Ecto.assoc_loaded?(found_approval.approval_logs)
      assert Ecto.assoc_loaded?(found_approval.approval_notes)
      assert Ecto.assoc_loaded?(found_approval.approval_costs)
    end

    test "delete", ~M[approval] do
      original_count = ApprovalRepo.count()

      # When
      ApprovalRepo.delete(approval.id)

      current_count = ApprovalRepo.count()
      assert current_count == original_count - 1
    end

    test "uploads attachment ", ~M[approval] do
      with_mock ExAws, request: fn _, _ -> {:ok, ""} end do
        original_count = AppCount.Repo.count(AppCount.Approvals.ApprovalAttachment)
        data = File.read!(Path.expand("../../resources/Sample1.pdf", __DIR__))
        uuid = AppCount.UploadServer.initialize_upload(1, "Sample1.pdf", "application/pdf")
        AppCount.UploadServer.push_piece(uuid, data, 1)

        %AppCount.Approvals.ApprovalAttachment{}
        |> AppCount.Approvals.ApprovalAttachment.changeset(%{
          attachment: %{uuid: uuid},
          approval_id: approval.id
        })
        |> AppCount.Repo.insert()

        current_count = AppCount.Repo.count(AppCount.Approvals.ApprovalAttachment)

        assert current_count == original_count + 1
      end
    end
  end
end
