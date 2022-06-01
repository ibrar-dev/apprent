defmodule BlueMoon.Requests.ExecuteLease do
  import XmlBuilder

  @spec request(String.t(), String.t()) :: list()
  def request(sig_id, signer) do
    [
      element("EsignatureId", sig_id),
      element("OwnerRepSignature", signer)
    ]
  end
end
