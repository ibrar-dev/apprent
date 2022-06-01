defmodule AppCountCom.MJMLCompiler do
  @compile_command Path.expand("../../assets/node_modules/mjml/bin/mjml", __DIR__)
  @layout_path Path.expand("./mjml/layout/", __DIR__)
  require Logger

  @spec compile_mjml() :: 0 | 1
  def compile_mjml do
    ## Do not remove this IO.inspect
    ## removing this IO inspect causes the deployment to not actually compile the mjml on production
    ## for more details ask David Astor
    IO.inspect("Hitting Compile MJML")

    Path.wildcard("#{@layout_path}/*.mjml")
    |> Enum.reduce(0, &compile_templates/2)
  end

  def compile_templates(layout, success_code) do
    layout_string = File.read!(layout)
    name = Path.basename(layout, ".mjml")
    path = Path.expand("./mjml/#{name}/", __DIR__)
    template_file = "#{path}/__template__.mjml"

    new_code =
      Path.wildcard("#{path}/**/*.mjml")
      |> Enum.reduce(
        success_code,
        fn p_name, succ ->
          base = Path.basename(p_name)
          IO.puts("compiling #{base}")
          sub = String.replace(p_name, ~r/.*mjml\/#{name}\/(.*)#{base}/, "\\1")
          layout_string = String.replace(layout_string, "TEMPLATE_PATH", "./#{sub}#{base}")
          File.write!(template_file, layout_string)

          target =
            String.replace(p_name, ".mjml", ".eex")
            |> String.replace(~r/mjml\/.*\//, "templates/#{name}/")

          case System.cmd(@compile_command, ["-mo", target, template_file]) do
            {"", 0} ->
              IO.puts("success")
              succ

            {error, code} ->
              Logger.error("error: #{error}")
              Logger.error("code: #{code}")
              1
          end
        end
      )

    File.rm(template_file)
    new_code
  end
end
