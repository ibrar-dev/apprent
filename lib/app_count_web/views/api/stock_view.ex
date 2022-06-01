defmodule AppCountWeb.API.StockView do
  use AppCountWeb, :view

  def render("index.json", %{stocks: stocks, properties: properties}) do
    %{
      stocks: render_many(stocks, __MODULE__, "stock.json"),
      properties: render_many(properties, __MODULE__, "property.json", as: :property)
    }
  end

  def render("property.json", %{property: property}) do
    %{
      id: property.id,
      name: property.name,
      stock_id: property.stock_id
    }
  end

  def render("stock.json", %{stock: stock}) do
    %{
      id: stock.id,
      name: stock.name,
      materials: Enum.map(stock.materials, &material/1),
      properties: Enum.map(stock.properties, &property/1)
    }
  end

  def material(material) do
    %{
      id: material.id,
      name: material.name,
      cost: Decimal.to_float(material.cost),
      inventory: material.inventory,
      desired: material.desired,
      ref_number: material.ref_number,
      type_id: material.type_id
    }
  end

  def property(p) do
    %{
      id: p.id,
      name: p.name
    }
  end
end
