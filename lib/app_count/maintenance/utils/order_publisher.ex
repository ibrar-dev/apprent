defmodule AppCount.Maintenance.Utils.OrderPublisher do
  # Idea: add other work_order events like: order canceled
  alias AppCount.Maintenance.Assignment
  alias AppCount.Core.OrderTopic
  alias AppCount.Core.OrderTopic.Info
  alias AppCount.Maintenance.OrderRepo
  alias AppCount.Accounts.AccountRepo
  alias AppCount.Maintenance.Order
  require Logger
  @tech_not_yet_assigned_message "Tech not yet assigned"

  # Created
  def publish_order_created_event(%Order{} = order) do
    order
    |> load_info(@tech_not_yet_assigned_message)
    |> OrderTopic.order_created(__MODULE__)

    order
  end

  # Assigned
  def publish_order_assigned_event(%Assignment{} = assignment) do
    assignment
    |> load_info()
    |> OrderTopic.order_assigned(__MODULE__)

    assignment
  end

  # Dispatched
  def publish_tech_dispatched_event(%Assignment{} = assignment) do
    assignment
    |> load_info()
    |> OrderTopic.tech_dispatched(__MODULE__)

    assignment
  end

  # Completed
  def publish_order_completed_event(%Assignment{} = assignment) do
    assignment
    |> load_info()
    |> OrderTopic.order_completed(__MODULE__)

    assignment
  end

  def load_info(%Assignment{} = assignment) do
    assignment =
      assignment
      |> AppCount.Repo.preload(:tech, prefix: assignment.__meta__.prefix)

    tech_name = assignment.tech.name

    assignment
    |> get_order()
    |> load_info(tech_name)
  end

  def load_info(%Order{} = order, tech_name) do
    order = get_order(order)
    tenant = order.tenant
    account = get_account(tenant)
    Info.new(tenant, account, order, tech_name)
  end

  # --- get from DB ---
  #
  defp get_order(%Order{} = order) do
    OrderRepo.get_aggregate(order.id)
  end

  defp get_order(%Assignment{order_id: order_id}) do
    OrderRepo.get_aggregate(order_id)
  end

  # gets account from DB or passes-thru nil when not found
  defp get_account(nil), do: nil
  defp get_account(%{account_id: nil}), do: nil
  defp get_account(tenant), do: AccountRepo.get_by_tenant(tenant)
end
