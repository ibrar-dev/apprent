defmodule AppCount.Approvals.Utils.ApprovalsTest do
  use AppCount.DataCase
  alias AppCount.Approvals.Utils.Approvals
  alias AppCount.Approvals.ApprovalRepo

  setup do
    property =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.get_requirement(:property)

    admin = Factory.admin_with_access([property.id])
    approval_params = approval_params(property, admin)

    ~M[property, admin, approval_params]
  end

  def approval_params(property, admin) do
    %{
      property_id: property.id,
      admin_id: admin.id,
      num: "3",
      type: "type",
      params: %{}
    }
  end

  describe "find_emailer/3" do
    test "empty logs", ~M[approval_params] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      {:ok, approval} = ApprovalRepo.insert(approval_params, prefix: client.client_schema)

      logs = []
      result = Approvals.find_emailer(approval, logs, client.client_schema)

      assert result == {:error, nil}
    end
  end
end
