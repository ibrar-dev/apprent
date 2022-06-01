defmodule AppCount.Decimal do
  defmacro __using__(_) do
    quote do
      import Kernel, except: [+: 2, -: 2, *: 2, /: 2]
      import AppCount.Decimal.Operators
    end
  end
end
