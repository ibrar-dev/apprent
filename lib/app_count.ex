defmodule AppCount do
  @adapters Application.compile_env(:app_count, :adapters, [])
  def adapters, do: @adapters

  def adapters(key, default_module), do: Keyword.get(@adapters, key, default_module)

  def env do
    Application.get_env(:app_count, AppCount)
  end

  def env(value), do: Map.get(env(), value)

  def june_first_2020 do
    # why June 1st?
    Timex.parse!("2020-06-01", "{YYYY}-{0M}-{0D}")
    |> Timex.beginning_of_day()
  end

  @spec current_time() :: %DateTime{}
  def current_time do
    case AppCount.env(:tz) do
      nil -> Timex.local()
      :timecop -> get_frozen()
      tz -> Timex.now(tz)
    end

    #    Uncomment for testing...
    #    Timex.parse!("2018-08-01T00:01Z", "{ISO:Extended}")
  end

  def current_date(), do: Timex.to_date(current_time())

  @spec namespaced_url(atom() | String.t()) :: String.t()
  def namespaced_url(sub) do
    env(:home_url)
    |> String.replace("://", "://#{sub}.")
  end

  defp get_frozen do
    case Process.whereis(:timecop) && Agent.get(:timecop, & &1) do
      nil -> Timex.local()
      time -> time
    end
  end

  ## mode of list
  def math_mode([]), do: nil

  def math_mode(list) when is_list(list) do
    h = math_hist(list)
    max = Map.values(h) |> Enum.max()
    h |> Enum.find(fn {_, val} -> val == max end) |> elem(0)
  end

  def math_hist([]), do: nil

  def math_hist(list) when is_list(list) do
    list
    |> Enum.reduce(%{}, fn tag, acc -> Map.update(acc, tag, 1, &(&1 + 1)) end)
  end
end
