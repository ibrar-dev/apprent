import moment from "moment";

const displayDateFormat = "MM/DD/YYYY";

const renderDate = (date, append) => (moment(date).format(displayDateFormat) + (append || ""));

const renderValidDate = (date, append) => (moment(date).isValid() ? renderDate(date, append) : "");

const renderMoveOut = (date) => (moment(date) < moment() ? "Vacant" : renderDate(date));

const renderMoveIn = (date) => {
  const display = renderValidDate(date);
  const append = !!display ? ` (${moment(date).diff(moment(), "days")} days)` : "";
  return display + append;
};

const renderItem = (items, name) => {
  const item = items.find((i) => i.name === name);
  if (!item) return "";
  const {scheduled, completed, notes} = item;
  // Completed task
  if (completed) return `Completed: ${moment(completed).format(displayDateFormat)}`;
  // Scheduled task, not yet completed
  if (scheduled) return `Scheduled: ${moment(scheduled).format(displayDateFormat)}`;
  // Unscheduled task, but has comments
  if (notes) return `Notes: ${notes}`;
  // Final fallback
  return "";
};

const renderComplete = ({completion}) => (completion ? "Yes" : "");

const renderers = {
  unitNumber: ({unit: {number}}) => number,
  readyDate: ({deadline}) => renderValidDate(deadline),
  moveOutDate: ({move_out_date: moveOut}) => renderMoveOut(moveOut),
  moveInDate: ({move_in_date: moveIn}) => renderMoveIn(moveIn),
  item: (items, name) => renderItem(items, name),
  complete: (card) => renderComplete(card),
};

export default renderers;
