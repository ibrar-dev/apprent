defmodule AppCountAuth.Base do
  defmacro __using__(_opts) do
    quote do
      def index(_user, _params) do
        true
      end

      def new(_user, _params) do
        true
      end

      def edit(_user, _params) do
        true
      end

      def show(_user, _params) do
        true
      end

      def create(_user, _params) do
        true
      end

      def update(_user, _params) do
        true
      end

      def delete(_user, _params) do
        true
      end

      defoverridable index: 2,
                     new: 2,
                     edit: 2,
                     show: 2,
                     create: 2,
                     update: 2,
                     delete: 2
    end
  end
end
