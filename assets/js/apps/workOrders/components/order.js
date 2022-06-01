import React from 'react';
import {connect} from 'react-redux';
import {withRouter} from 'react-router';
import OrderComponents from './orderComponents';
import actions from '../actions';

const orderStatus = (order) => {
  if (order.type == 'vendor') {
    return "outsourced"
  }

  if (order.cancellation) {
    return 'canceled';
  }

  let status = (order.assignments[0] || {status: 'open'}).status;
  if (["canceled", "rejected", "callback", "withdrawn", "revoked"].includes(status)) {
    return 'open';
  } else {
    return status;
  }
};

class Order extends React.Component {
  constructor(props) {
    super(props);
    actions.openWorkOrder(props.match.params.id, props.type);
  }

  otherOrdersForUnit() {
    const otherOrders = [];
    const {openWorkOrder, workOrders} = this.props;
    workOrders.open.forEach(order => {
      if (order.unit === openWorkOrder.unit && order !== openWorkOrder) {
        otherOrders.push(order);
      }
    });
    return otherOrders;
  }

  render() {
    const {openWorkOrder} = this.props;
    if (!openWorkOrder) {
      return <div/>;
    }
    const Component = OrderComponents[orderStatus(openWorkOrder)];
    return (
      <Component
        order={openWorkOrder}
        otherOrders={this.otherOrdersForUnit()}
      />
    );
  }
}

export default withRouter(connect(({openWorkOrder, workOrders, vendorOrders}) => {
  return {openWorkOrder, workOrders, vendorOrders};
})(Order));
