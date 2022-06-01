import {toCurr} from "../../../utils";
import React from "react";

const sortableStringColumn = (field) => {
  return {
    sorter: (a, b) => a[field] - b[field],
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

export {sortableStringColumn, numberRenderer, currencyRenderer, percentageRenderer, viewDetailedRender}