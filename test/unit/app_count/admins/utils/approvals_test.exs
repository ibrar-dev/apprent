defmodule AppCount.Admin.Utils.ApprovalsTest do
  use AppCount.DataCase
  alias AppCount.Approvals.ApprovalRepo
  alias AppCount.Approvals.Utils.Approvals

  def approval_attrs(property, admin) do
    %{
      property_id: property.id,
      admin_id: admin.id,
      num: "3",
      type: "type",
      params: %{}
    }
  end

  describe "get_next_num" do
    setup do
      property =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.get_requirement(:property)

      ~M[property]
    end

    test " no payee_id", ~M[property] do
      # When
      result = AppCount.Approvals.Utils.Approvals.get_next_num(nil, property.id)

      assert result == "#{property.id}-Error-1"
    end

    test " no property" do
      # When
      result = AppCount.Approvals.Utils.Approvals.get_next_num(1234, nil)

      assert result == "Error"
    end
  end

  describe "Approvals" do
    setup do
      builder =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_admin()

      property = PropBuilder.get_requirement(builder, :property)
      admin = PropBuilder.get_requirement(builder, :admin)

      approval_attrs = approval_attrs(property, admin)

      inner_params = %{
        "payee_id" => 3,
        "costs" => nil,
        "approver" => nil,
        "attachments" => nil
      }

      params = %{
        "params" => inner_params,
        "property_id" => property.id,
        "num" => nil
      }

      ~M[params , property, admin, approval_attrs]
    end

    test "create_approval, error", ~M[params] do
      # When
      result = Approvals.create_approval(params, "dasmen")

      assert {:error, :approval, _changeset, %{}} = result
    end

    test "create _approval, ok", ~M[params, admin] do
      original_count = ApprovalRepo.count()

      params =
        params
        |> Map.put("admin_id", admin.id)
        |> Map.put("type", "SOME-TYPE")

      # When
      result = Approvals.create_approval(params, "dasmen")

      current_count = ApprovalRepo.count()
      assert current_count == original_count + 1
      assert {:ok, map} = result

      assert Map.keys(map) == [:approval, :logs]
      assert map.approval.id
    end

    test "generate_num, if number exists, do nothing", ~M[ property] do
      input_and_output_params = %{
        "num" => "10",
        "params" => %{"approver" => nil, "attachments" => nil, "costs" => nil, "payee_id" => 3},
        "property_id" => property.id
      }

      # When
      result = Approvals.generate_num(input_and_output_params)
      # Then
      assert input_and_output_params == result
    end

    test "generate_num, if number is nil. create a num ", ~M[ params, property] do
      params = %{params | "num" => nil}

      expected_result = %{
        "num" => "3-#{property.id}-1",
        "params" => %{"approver" => nil, "attachments" => nil, "costs" => nil, "payee_id" => 3},
        "property_id" => property.id
      }

      # When
      result = Approvals.generate_num(params)
      # Then
      assert expected_result == result
    end

    test "generate_num, if number is empty-string. create a num ", ~M[ params, property] do
      params = %{params | "num" => ""}

      expected_result = %{
        "num" => "3-#{property.id}-1",
        "params" => %{"approver" => nil, "attachments" => nil, "costs" => nil, "payee_id" => 3},
        "property_id" => property.id
      }

      # When
      result = Approvals.generate_num(params)
      # Then
      assert expected_result == result
    end
  end
end
