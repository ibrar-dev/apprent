defmodule Yardi.Request do
  alias AppCount.Xml.Element
  alias AppCount.Xml.SOAP.Request

  defmacro __using__(params) do
    quote do
      alias AppCount.Xml.Element

      defmacrop element(name, value) do
        quote do
          %Element{name: unquote(name), content: unquote(value)}
        end
      end

      defmacrop element(name, attributes, value) do
        quote do
          %Element{name: unquote(name), attributes: unquote(attributes), content: unquote(value)}
        end
      end

      def perform(options) do
        Yardi.Request.perform_request(
          options[:credentials].url,
          unquote(params),
          request_body(options)
        )
      end
    end
  end

  def perform_request(url, params, request_body) do
    data = %Element{
      name: params[:container],
      attributes: %{
        xmlns: params[:xmlns]
      },
      content: request_body
    }

    Request.request(url <> params[:action], data, soap_action: params[:soap_action])
  end
end
