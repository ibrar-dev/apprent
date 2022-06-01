import React from "react";
import {connect} from "react-redux";
import {Button} from "reactstrap";
import {
  Profile,
  Ledger,
  WorkOrders,
  Interactions,
  Leases,
  Documents,
  Account,
  Mailer,
  Rewards,
  Occupancy
} from "./tenantDetails";
import TabbedBox from "../../../components/tabbedBox";

const links = [
  {icon: false, data: Ledger, label: "Ledger", id: 0},
  {icon: false, data: Profile, label: "Profile", id: 1},
  {icon: false, data: Occupancy, label: "Occupancy", id: 9},
  {icon: false, data: Leases, label: "Leases", id: 4},
  {icon: false, data: WorkOrders, label: "Work Orders", id: 2},
  {icon: false, data: Interactions, label: "Memos", id: 3},
  {icon: false, data: Documents, label: "Documents", id: 5},
  {icon: false, data: Rewards, label: "Rewards", id: 8},
  {icon: false, data: Account, label: "Account", id: 6},
  {icon: false, data: Mailer, label: "Mailer", id: 7}
];

class Tenant extends React.Component {
  state = {mode: links[0]};

  _footer() {
    return <div>
      <Button
        onClick={() => this.props.history.push("/tenants", {})}
        color="success"
        className="btn-block mt-3"
      >
        <i style={{color: "white"}} className="fas fa-long-arrow-alt-left"/> Back
      </Button>
    </div>
  }

  setTab(mode) {
    this.setState({...this.state, mode})
  }

  render() {
    const {tenant, tenantId} = this.props;
    if (!tenant || tenant.id !== tenantId) return <div/>;
    const {mode} = this.state;

    const header = (
      <div
        className="d-flex card-header align-items-center"
        style={{border: "1px solid #e4e6eb", borderBottom: "none"}}
      >
        {tenant.first_name} {tenant.last_name}
      </div>
    );

    return (
      <TabbedBox
        links={links}
        active={mode.id}
        header={header}
        footer={this._footer()}
        onNavigate={this.setTab.bind(this)}
      >
        <mode.data tenant={tenant}/>
      </TabbedBox>
    );
  }
}

const mapStateToProps = ({tenant}) => ({tenant});
export default connect(mapStateToProps)(Tenant);
