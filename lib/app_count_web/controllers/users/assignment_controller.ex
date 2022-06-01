defmodule AppCountWeb.Users.AssignmentController do
  use AppCountWeb.Users, :controller
  alias AppCount.Accounts
  alias AppCount.Maintenance.Assignment
  alias AppCount.Repo

  @doc """
  Given work order and assignment, render edit form
  """
  def edit_rating(conn, %{"assignment_id" => id}) do
    assign_tuple = get_assignment(conn.assigns.user.id, id)

    case assign_tuple do
      {:ok, assignment} ->
        render(conn, "edit_rating.html", assignment: assignment)

      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> redirect(to: "/work_orders")
    end
  end

  @doc """
  Update rating on work order - incoming params we care about:

  %{
    "assignment" => %{"rating" => "4", "tenant_comment" => "asdfasdfa"},
    "id" => "99963"
  }
  """
  def update(conn, params) do
    %{
      "id" => id,
      "assignment" => %{
        "rating" => rating,
        "tenant_comment" => tenant_comment
      }
    } = params

    assign_tuple =
      get_assignment(
        conn.assigns.user.id,
        id,
        %{
          rating: rating,
          tenant_comment: tenant_comment
        }
      )

    case assign_tuple do
      {:ok, assignment} ->
        {:ok, _} = Repo.update(assignment)

        redirect(conn, to: "/work_orders")

      # Assignment not found
      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> redirect(to: "/work_orders")
    end
  end

  def get_assignment(user_id, id, attrs \\ %{}) do
    assignment = Accounts.get_assignment(user_id, id)

    if is_nil(assignment) do
      {:error, "not found"}
    else
      assignment_cs =
        assignment
        |> Assignment.rating_changeset(attrs)

      {:ok, assignment_cs}
    end
  end
end
