defmodule AppCount.Accounting.ChecksTest do
  use AppCount.DataCase
  import Ecto.Query
  import Mock
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Data
  alias AppCount.Accounting.Check

  @moduletag :checks

  setup do
    {:ok, check: insert(:check)}
  end

  # test "list_checks", %{check: check} do
  #   result = Accounting.list_checks()
  #   assert length(result) == 1
  #   assert hd(result).id == check.id
  # end

  @tag :slow
  test "show_check" do
    # this render_fn could be a stub
    render_fn = &AppCountWeb.LetterPreviewer.render_check_template/1
    client = AppCount.Public.get_client_by_schema("dasmen")

    check =
      from(
        c in Check,
        select: c,
        order_by: [
          desc: c.id
        ],
        limit: 1
      )
      |> Repo.one(prefix: client.client_schema)

    with_mock Accounting,
              [:passthrough],
              save_to_aws: fn _, _, _ -> {:ok, %{check: "passed"}} end do
      pdf =
        Accounting.show_check(check.id, render_fn)
        |> Base.decode64!()
        |> :erlang.binary_to_term()
        |> case do
          {:ok, binary} -> Data.file_type(binary)
          {:error, _} -> nil
        end

      assert pdf == :pdf
    end
  end

  # test "find_pdfs" do
  #   check =
  #     from(
  #       c in Check,
  #       select: c,
  #       order_by: [
  #         desc: c.id
  #       ],
  #       limit: 1
  #     )
  #     |> Repo.one()

  #   pdf =
  #     Accounting.find_pdfs([check.id])
  #     |> Base.decode64!()
  #     |> :erlang.binary_to_term()
  #     |> Data.file_type()

  #   assert pdf == :pdf
  # end

  # @tag :slow
  # test "create_new_check" do
  #   with_mock Accounting,
  #             [:passthrough],
  #             save_to_aws: fn _, _, _ -> {:ok, %{check: "passed"}} end do
  #     render_check_template_fn = &AppCountWeb.LetterPreviewer.render_check_template/1

  #     {:ok, result} =
  #       AppCount.Accounting.Utils.Checks.create_new_check(
  #         %{
  #           "payee_id" => insert(:payee).id,
  #           "date" => "2019-10-03",
  #           "bank_account_id" => insert(:bank_account).id,
  #           "amount_lang" => "THREE THOUSAND",
  #           "amount" => 3000
  #         },
  #         render_check_template_fn
  #       )

  #     pdf =
  #       Base.decode64!(result.check_pdf)
  #       |> :erlang.binary_to_term()
  #       |> case do
  #         {:ok, binary} -> Data.file_type(binary)
  #         {:error, _} -> nil
  #       end

  #     assert pdf == :pdf
  #   end
  # end

  # test "create_check" do
  #   {:ok, result} =
  #     Accounting.create_check(%{
  #       "payee_id" => insert(:payee).id,
  #       "date" => "2018-05-26",
  #       "bank_account_id" => insert(:bank_account).id,
  #       "amount" => 350
  #     })

  #   assert result.number == 1
  # end

  # test "update_check", %{check: check} do
  #   {:ok, %Check{} = result} =
  #     Accounting.update_check(
  #       check.id,
  #       %{
  #         "number" => "1212121212",
  #         "amount" => 200
  #       }
  #     )

  #   assert result.number == 1_212_121_212
  # end

  # test "delete_check with cascade", %{check: check} do
  #   admin = AppCount.UserHelper.new_admin()

  #   Accounting.delete_check(admin, check.id, "true")
  #   refute Repo.get(Check, check.id)
  # end

  # test "delete_check without cascade", %{check: check} do
  #   admin = AppCount.UserHelper.new_admin()

  #   Accounting.delete_check(admin, check.id, "false")
  #   refute Repo.get(Check, check.id)
  # end

  # test "get_check", %{check: check} do
  #   assert Accounting.get_check(check.id)
  # end
end
