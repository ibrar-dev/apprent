defmodule AppCount.Finance.SoftLedgerTranslationRepo do
  @moduledoc """
  Given an AppCount struct this lets us find the _id objects in SoftLedger
  """
  use AppCount.Core.GenericRepo,
    schema: AppCount.Finance.SoftLedgerTranslation,
    preloads: [],
    topic: AppCount.Core.SoftLedgerTranslationTopic

  def get_by_app_count(app_count_struct, app_count_id) do
    get_by(app_count_id: app_count_id, app_count_struct: app_count_struct)
  end

  def soft_ledger_account_id(app_count_account_id) do
    result = get_by_app_count("AppCount.Finance.Account", app_count_account_id)

    if result == nil do
      nil
    else
      result.soft_ledger_underscore_id
    end
  end

  # Instead of using the schema and id of the inserted row,
  # we need to get schema and id of the translated app_count struct
  def created_event(%{app_count_struct: struct, app_count_id: id}) do
    @topic.created(
      %{subject_name: "#{struct}", subject_id: id},
      __MODULE__
    )
  end

  # Instead of using the schema and id of the inserted row,
  # we need to get schema and id of the translated app_count struct
  def changed_event(%{app_count_struct: struct, app_count_id: id}, _changeset) do
    @topic.changed(
      %{subject_name: "#{struct}", subject_id: id},
      __MODULE__
    )
  end

  # Instead of using the schema and id of the inserted row,
  # we need to get schema and id of the translated app_count struct
  def deleted_event(%{app_count_struct: struct, app_count_id: id}) do
    @topic.deleted(
      %{subject_name: "#{struct}", subject_id: id},
      __MODULE__
    )
  end
end
