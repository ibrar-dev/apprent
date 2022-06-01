import React from "react";
import moment from "moment";
import CardItemDetail from "./cardItemDetail";

// changes the date to red if it's in the past for the "Ready Date" or "Move In" columns
const dateStyle = (scheduled) => {
  const color = (moment(scheduled) < moment()) ? "red" : "black";
  return {color};
};

const displayValue = (item) => {
  // No item at all - everything is null baby null
  if (!item) {
    return <i className="fas fa-minus"/>;
  }

  const {scheduled, completed, notes} = item;

  // Completed task
  if (completed) {
    return <i className="fas fa-check-circle text-success"/>
  }

  // Scheduled task, not yet completed
  if (scheduled) {
    const formatted = moment(scheduled).format("MM/DD/YYYY")
    const styledDate = <span style={dateStyle(scheduled)}>{formatted}</span>
    return formatted ? styledDate : <i className="fas fa-times-circle"/>
  }

  // Unscheduled task, but has comments
  if (notes) {
    return <i className="far fa-comment" />;
  }

  // Final fallback
  return <i className="fas fa-minus" />;
};

class ItemCell extends React.Component {
  state = {};

  toggleOpen() {
    this.setState({open: !this.state.open})
  }

  render() {
    const {item, name, cardId} = this.props;
    const {open} = this.state;
    const elementId = `item-${cardId}-${name.replace(" ", "-")}`;
    return <td id={elementId} className="text-center nowrap">
      <a onClick={this.toggleOpen.bind(this)}>
        {displayValue(item)}
      </a>
      {open && <CardItemDetail name={name} toggle={this.toggleOpen.bind(this)} item={item || {card_id: cardId, name}}/>}
    </td>;
  }
}

export default ItemCell;
