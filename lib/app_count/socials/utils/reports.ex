defmodule AppCount.Socials.Utils.Reports do
  alias AppCount.Repo
  alias AppCount.Socials.Report

  def create_report(params) do
    %Report{}
    |> Report.changeset(params)
    |> Repo.insert()
  end

  def delete_report(id) do
    Repo.get(Report, id)
    |> Repo.delete()
  end
end
