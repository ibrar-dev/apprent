defmodule Mix.Tasks.TailLogs do
  use Mix.Task

  @shortdoc "Tails log files"
  @spec run(any) :: no_return()
  def run(_) do
    path =
      Path.expand("log/debug.log")
      |> to_charlist

    Port.open({:spawn_executable, '/usr/bin/tail'}, [
      :stream,
      {:line, 16384},
      {:args, ['-f', path]}
    ])
    |> Process.link()

    IO.write("starting logs...\n")
    loop()
  end

  def loop() do
    receive do
      {_, {:data, {:eol, []}}} ->
        loop()

      {_, {:data, {:eol, line}}} ->
        IO.write("#{line}\n")
        loop()

      _ ->
        loop()
    end
  end
end
