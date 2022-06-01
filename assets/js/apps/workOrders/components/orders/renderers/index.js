import {
  CreateOrderButton,
  categorySorter,
  dateTimeRenderer,
  formatTimeStamp,
  multiStringRenderer,
  notesRenderer,
  propertyUnitRenderer,
  propertyUnitSorter,
  residentRenderer,
  residentSorter,
  sortableDateColumn,
  sortableStringColumn,
  unassignedActionRenderer,
  viewRendererForExport,
} from "./unassignedRenderers";

import {
  assignedAtRenderer,
  assignedAtSorter,
  assignedAtTimeString,
  assignedToRenderer,
  assignedToSorter,
  clickableCell,
  getAssignedTo,
} from "./assignedRenderers";

import {
  completedAtRender,
  completedAtString,
  completedDateSorter,
  daysIncompleteSorter,
  ratingRender,
  ratingSorter,
  timeOpen,
  timeOpenString,
} from "./completedRenderers";

import {
  cancelledAdmin,
  cancelledAdminSorter,
  cancelledAdminString,
  cancelledOnRender,
  cancelledOnSorter,
  cancelledOnString,
  cancelledReason,
  cancelledReasonSorter,
  cancelledReasonString,
  submittedOnRender,
  unitRender,
  unitSorter,
} from "./cancelledRenderers";

function priorityRowRender(order) {
  if (!order || !order.priority) return {className: `${order.callback ? "text-danger" : ""}`};
  if (order.priority === 3) return {className: `${order.callback ? "text-danger" : ""} alert-warning`};
  if (order.priority === 5) return {className: `${order.callback ? "text-danger" : ""} alert-danger`};
  return {className: `${order.callback ? "text-danger" : ""}`};
}

export {
  CreateOrderButton,
  assignedAtRenderer,
  assignedAtSorter,
  assignedAtTimeString,
  assignedToRenderer,
  assignedToSorter,
  cancelledAdmin,
  cancelledAdminSorter,
  cancelledAdminString,
  cancelledOnRender,
  cancelledOnSorter,
  cancelledOnString,
  cancelledReason,
  cancelledReasonSorter,
  cancelledReasonString,
  categorySorter,
  clickableCell,
  completedAtRender,
  completedAtString,
  completedDateSorter,
  dateTimeRenderer,
  daysIncompleteSorter,
  formatTimeStamp,
  getAssignedTo,
  multiStringRenderer,
  notesRenderer,
  priorityRowRender,
  propertyUnitRenderer,
  propertyUnitSorter,
  ratingRender,
  ratingSorter,
  residentRenderer,
  residentSorter,
  sortableDateColumn,
  sortableStringColumn,
  submittedOnRender,
  timeOpen,
  timeOpenString,
  unassignedActionRenderer,
  unitRender,
  unitSorter,
  viewRendererForExport,
};
