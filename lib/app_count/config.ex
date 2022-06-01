defmodule AppCount.Config do
  # AppCount.Config.settings()
  def settings do
    Application.get_env(:app_count, AppCount)
  end

  def env do
    settings()
    |> Map.get(:environment)
  end
end
