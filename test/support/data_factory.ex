defmodule AppCount.DataFactory do
  use ExMachina.Ecto, repo: AppCount.Repo
  alias AppCount.Data

  defmacro __using__(_opts) do
    quote do
      def upload_factory do
        %Data.Upload{
          uuid: UUID.uuid4(),
          filename: "Something.ext",
          content_type: "application/octet-stream",
          size: 1024
        }
      end
    end
  end
end
