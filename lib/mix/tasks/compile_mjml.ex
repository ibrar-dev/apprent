defmodule Mix.Tasks.CompileMjml do
  @moduledoc """
  Compiles MJML templates to EEX.
  """
  use Mix.Task

  @shortdoc "Compiles MJML templates to EEX."
  @spec run(any) :: no_return()
  def run(_) do
    exit({:shutdown, AppCountCom.MJMLCompiler.compile_mjml()})
  end
end
