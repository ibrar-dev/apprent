import React from "react";
import {titleize, toCurr} from "../../../../../utils";
import moment from 'moment';
import actions from '../../../actions';

const sortableStringColumn = (field) => {
  return {
    sorter: (a, b) => a[field] - b[field],
    sortDirections: ['ascend', 'descend']
  }
};

const complexSortColumn = (field) => {
  const new_field = field.concat('count');
  return {
    sorter: (a, b) => {
      return getValue(a, new_field) - getValue(b, new_field)
    },
    sortDirections: ['ascend', 'descend']
  }
};

function numberRenderer(data) {
  return <span>{Math.round(data)}</span>
}

function currencyRenderer(data) {
  return <span>{toCurr(data)}</span>
}

function percentageRenderer(data) {
  return <span>{data}%</span>
}

function viewDetailedRender({count}) {
  return <span className={"cursor-pointer"}>{count}</span>
}

function dateRenderer(data) {
  return <span>{moment(data).format("MM/DD/YYYY")}</span>
}

function avgData(data, field) {
  const {total, count} = data.reduce((acc, d) => {
    return {total: eval(`${acc.total} + ${d[field]}`), count: acc.count + 1}
  }, {total: 0, count: 0});
  return (total / count).toFixed(2);
}

function getTotal(data, field) {
  return data.reduce((acc, d) => {
    return eval(`${acc} + ${d[field]}`)
  }, 0);
}

function getValue(data, pathToData) {
  return pathToData.reduce((acc, f) => {
    return acc[f]
  }, data);
}

function totalNestedData(data, pathToData) {
  return data.reduce((acc, f) => {
    return eval(`${getValue(f, pathToData)} + ${acc}`)
  }, 0)
}

function clickableCell(record, pathToData) {
  const data = {
    title: `Detailed ${titleize(pathToData[pathToData.length - 1])} for ${record.name}`,
    data: pathToData.reduce((acc, f) => (acc[f]), record)
  };
  return {
    onClick: () => actions.setDetailedData(data),
  }
}

export {
  sortableStringColumn,
  complexSortColumn,
  numberRenderer,
  percentageRenderer,
  viewDetailedRender,
  getTotal,
  avgData,
  getValue,
  totalNestedData,
  currencyRenderer,
  dateRenderer,
  clickableCell
}
