defmodule AppCount.DevDNS do
  @behaviour DNS.Server
  use DNS.Server

  def handle(record, _cl) do
    query = hd(record.qdlist)

    case query.type do
      :a -> resource = %DNS.Resource{
        domain: query.domain,
        class: query.class,
        type: query.type,
        ttl: 600,
        data: {127, 0, 0, 1}
      }
            with_response_header = Map.put(record, :header, Map.merge(record.header, %{qr: true}))
            %{with_response_header | anlist: [resource]}
      _ -> Map.put(record, :header, Map.merge(record.header, %{qr: true, rcode: 3}))
    end
  end
end