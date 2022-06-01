import React, {Component} from 'react';
import {Modal} from 'reactstrap';
import MoveIns from './screens/moveIns';
import MoveOuts from './screens/moveOuts';
import PartsPending from './screens/partsPending';
import ExpiringLeases from './screens/expiringLeases/index';
import OnNotice from './screens/onNotice';
import TodaysTours from './screens/todaysTours/index';
import OpenOrders from './screens/openOrders/index';
import PausedOrder from "./screens/pausedOrders/index";
import ActiveOrder from "./screens/activeOrders/index";
import MakeReady from "./screens/makeReadys/index";
import AvailableUnits from "./screens/availableUnits/index";
import UncollectedPackages from "./screens/uncollectedPackages/index";
import NotInspected from './screens/notInspected';
import NoChargeLeases from './screens/noChargesLeases';
import PastExpectedMoveOut from './screens/pastExpectedMoveOut';
import NoDefaultCharges from './screens/noDefaultCharges';
import PreleasedUnits from './screens/preleasedUnits';

const componentToDisplay = (type, toggle) => {
  switch (type){
    case "move_ins":
      return <MoveIns />;
    case "move_outs":
      return <MoveOuts />;
    case "parts_pending":
      return <PartsPending toggle={toggle}/>;
    case "expiring_leases":
      return <ExpiringLeases />;
    case "on_notice":
      return <OnNotice />;
    case "todays_tours":
      return <TodaysTours />;
    case "open_orders":
      return <OpenOrders />;
    case "paused_orders":
      return <PausedOrder />;
    case "active_orders":
      return <ActiveOrder />;
    case "make_readys":
      return <MakeReady />;
    case "available_units":
      return <AvailableUnits />;
    case "uncollected_packages":
      return <UncollectedPackages />;
    case "not_inspected":
      return <NotInspected />;
    case "no_charge_leases":
      return <NoChargeLeases />;
    case "past_move_outs":
      return <PastExpectedMoveOut/>;
    case "no_default_charges":
      return <NoDefaultCharges />;
    case "preleased_units":
      return <PreleasedUnits />;
    default:
      return <h5>No Data :(</h5>;
  }
}

class DashBoardModal extends Component {
  state = {}

  render() {
    const {toggle, type} = this.props;
    return (
      <Modal isOpen={true} toggle={toggle} size="lg">
        {componentToDisplay(type, toggle)}
      </Modal>
    )
  }
}

export default DashBoardModal;