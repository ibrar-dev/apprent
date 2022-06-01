import moment from "moment";
import colors from "../../../../usageDashboard/components/colors";

function reducedProperties(data) {
  const properties = {};
  // eslint-disable-next-line camelcase
  data.forEach(({id, completion_date, property: {name}}) => {
    if (name === "Dasmen Sandbox") return;
    if (properties[name]) return properties[name].push({date: completion_date, id});
    if (!properties[name]) {
      properties[name] = [];
      return properties[name].push({date: completion_date, id});
    }
  });
  return properties;
}

function reducedPropertiesOpen(data) {
  const properties = {};
  data.forEach((h) => {
    if (h.property.name === "Dasmen Sandbox") return;
    if (properties[h.property.name]) return properties[h.property.name].push({date: h.date, open: h.open});
    if (!properties[h.property.name]) {
      properties[h.property.name] = [];
      return properties[h.property.name].push({date: h.date, open: h.open, id: h.id});
    }
  });
  return properties;
}

function propertiesList(data) {
  const properties = [];
  data.forEach((o) => {
    if (o.property.name === "Dasmen Sandbox") return;
    if (properties.indexOf(o.property.name) === -1) return properties.push(o.property.name);
  });
  return properties;
}

function barChartDataFunctionOpen(propertyList, windowProperties) {
  const {length} = Object.keys(propertyList);
  const data = {
    datasets: [],
    labels: [],
  };
  Object.keys(propertyList).map((k, i) => {
    const windowProperty = windowProperties.find((p) => p.name === k);
    const col = windowProperty.color || colors(i, length);
    const propData = propertyList[k].map((h) => {
      if (data.labels.indexOf(moment.utc(h.date).format("MM-DD-YY")) === -1) data.labels.push(moment.utc(h.date).format("MM-DD-YY"));
      return {x: moment.utc(h.date).format("MM-DD-YY"), y: h.open};
    });
    data.datasets.push({
      label: k,
      data: propData,
      backgroundColor: col.replace(/, .*\)/, ",0.5)"),
      borderColor: col,
    });
  });
  return data;
}

function barChartDataFunction(propertyList, windowProperties) {
  const {length} = Object.keys(propertyList);
  const data = {
    datasets: [],
    labels: [],
  };
  Object.keys(propertyList).map((k, i) => {
    const windowProperty = windowProperties.find((p) => p.name === k);
    const col = windowProperty.color || colors(i, length);
    propertyList[k].forEach((o) => {
      if (data.labels.indexOf(moment(o.date).format("MM-DD-YY")) === -1) return data.labels.push(moment(o.date).format("MM-DD-YY"));
    });
    const propData = data.labels.map((l) => {
      const total = propertyList[k].filter((o) => moment(o.date).format("MM-DD-YY") === l).length;
      return {x: l, y: total};
    });
    propData.sort((a, b) => moment(a.x).diff(moment(b.x)));
    data.datasets.push({
      label: k,
      data: propData,
      backgroundColor: col.replace(/, .*\)/, ",0.5)"),
      borderColor: col,
    });
  });
  data.labels.sort((a, b) => moment(a).diff(moment(b)));
  return data;
}

function chartDataFunction(orders) {
  const data = {
    datasets: [{
      data: [],
      backgroundColor: [],
      borderColor: [],
    }],
    labels: [],
  };
  const agg = [];
  const labels = [];
  orders.forEach((o) => {
    if (labels.indexOf(o.category) === -1) labels.push(o.category);
  });
  const {length} = labels;
  labels.forEach((l, i) => {
    const col = colors(i, length);
    const total = orders.filter((o) => o.category === l).length;
    agg.push({
      label: l,
      borderColor: col,
      backgroundColor: col.replace(/, .*\)/, ",0.8)"),
      total,
    });
  });
  agg.sort((a, b) => b.total - a.total);
  agg.forEach((cat) => {
    data.datasets[0].backgroundColor.push(cat.backgroundColor);
    data.datasets[0].borderColor.push(cat.borderColor);
    data.datasets[0].data.push(cat.total);
    data.labels.push(cat.label);
  });
  return data;
}

function scChartDataFunction(orders, category) {
  const data = {
    datasets: [{
      data: [],
      backgroundColor: [],
      borderColor: [],
    }],
    labels: [],
  };
  const agg = [];
  const labels = [];
  const filteredOrders = orders.filter((o) => o.category === category);
  filteredOrders.forEach((o) => {
    if (labels.indexOf(o.subcategory) === -1) labels.push(o.subcategory);
  });
  const {length} = labels;
  labels.forEach((l, i) => {
    const col = colors(i, length);
    const total = filteredOrders.filter((o) => o.subcategory === l).length;
    agg.push({
      label: l,
      borderColor: col,
      backgroundColor: col.replace(/, .*\)/, ",0.8)"),
      total,
    });
  });
  agg.sort((a, b) => b.total - a.total);
  agg.forEach((cat) => {
    data.datasets[0].backgroundColor.push(cat.backgroundColor);
    data.datasets[0].borderColor.push(cat.borderColor);
    data.datasets[0].data.push(cat.total);
    data.labels.push(cat.label);
  });
  return data;
}

function multiBarChartData(data, dataKey = "category") {
  const categories = [...new Set(data.map((o) => o[dataKey]))];
  const {length} = categories;
  const totalDataset = [];
  const completed = [];

  categories.forEach((label, i) => {
    const color = colors(i, length);
    const total = data.filter((o) => o[dataKey] === label).length;
    const totalCompleted = data.filter((o) => o[dataKey] === label && o.status === "completed").length;
    totalDataset.push({label, color, total});
    completed.push({label, color: color.replace(/, .*\)/, ",0.8)"), total: totalCompleted});
  });
  const sortedTotal = [...totalDataset].sort((a, b) => b.total - a.total);

  return {
    labels: sortedTotal.map((x) => x.label),
    datasets: [
      {
        label: "Total Orders",
        backgroundColor: sortedTotal.map((x) => x.color),
        data: sortedTotal.map((x) => x.total),
      },
      {
        label: "Completed Orders",
        backgroundColor: sortedTotal.map((x) => completed.find((c) => c.label === x.label).color),
        data: sortedTotal.map((x) => completed.find((c) => c.label === x.label).total),
      },
    ],
  };
}

function multiBarChartSubData(data, category) {
  const filtered = data.filter((ord) => ord.category === category);
  return multiBarChartData(filtered, "subcategory");
}

function pieChartData(data, dataKey = "tech_id", labelKey = "tech_name") {
  const categories = [...new Set(data.map((o) => o[dataKey]))];
  const {length} = categories;
  const totalDataset = categories.map((key, i) => (
    {
      key,
      label: data.find((o) => o[dataKey] === key)[labelKey],
      color: colors(i, length),
      total: data.filter((o) => o[dataKey] === key).length,
    }
  ));
  const sortedTotal = [...totalDataset].sort((a, b) => b.total - a.total);

  return {
    labels: sortedTotal.map((x) => x.label),
    keys: sortedTotal.map((x) => x.key),
    datasets: [
      {
        label: "Total Orders",
        backgroundColor: sortedTotal.map((x) => x.color),
        data: sortedTotal.map((x) => x.total),
      },
    ],
  };
}

function pieChartSubData(data, tech_id) {
  const filtered = data.filter((ord) => ord.tech_id === tech_id);
  return pieChartData(filtered, "category", "category");
}


export {
  reducedProperties,
  propertiesList,
  barChartDataFunction,
  barChartDataFunctionOpen,
  reducedPropertiesOpen,
  chartDataFunction,
  scChartDataFunction,
  pieChartData,
  multiBarChartData,
  multiBarChartSubData,
  pieChartSubData,
};
