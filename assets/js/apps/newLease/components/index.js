import React, {Component} from 'react';
import {connect} from 'react-redux';
import TabbedBox from '../../../components/tabbedBox';
import {Basics, SecurityDeposit, BedBugs, Concessions, Gate, Other, WasherDryer, Finish} from "./steps";
import defaultLease from "./defaultLease";
import actions from '../actions';

const links = [
  {icon: false, data: Basics, label: 'Basics', id: 0},
  {icon: false, data: SecurityDeposit, label: 'Security Deposit & Keys', id: 1},
  {icon: false, data: BedBugs, label: 'Bed Bugs', id: 2},
  {icon: false, data: Concessions, label: 'Concessions', id: 3},
  {icon: false, data: Gate, label: 'Gate Access', id: 4},
  {icon: false, data: WasherDryer, label: 'Washer/Dryer', id: 5},
  {icon: false, data: Other, label: 'Other', id: 6},
  {icon: false, data: Finish, label: 'Execute', id: 7}
];

class LeaseCreation extends Component {
  constructor(props) {
    super(props);
    this.state = {tab: links[0], lease: defaultLease(props.lease)};
  }

  componentWillReceiveProps(nextProps, nextContext) {
    if (!this.firstLoad) {
      this.setState({lease: defaultLease(nextProps.lease)});
      this.firstLoad = true;
    }
  }

  setTab(tab) {
    this.setState({tab});
  }

  change(field, value) {
    this.setState({lease: {...this.state.lease, [field]: value}}, () => {
      if (['end_date', 'start_date', 'unit'].includes(field)) {
        actions.refreshLeaseParams(this.state.lease).then(r => {
          this.setState({lease: {...this.state.lease, rent: r.data.rent}});
        })
      }
    });
  }

  changeLease(value){
    this.setState({lease: {...this.state.lease, ...value}}, () => {
      actions.refreshLeaseParams(this.state.lease)
    })
  }

  render() {
    const {tab, lease} = this.state;
    return <TabbedBox links={links} active={tab.id} onNavigate={this.setTab.bind(this)}>
      <div className="pl-4">
        <tab.data lease={lease} changeLease={this.changeLease.bind(this)} onChange={this.change.bind(this)}/>
      </div>
    </TabbedBox>
  }
}

export default connect(({lease, availableUnits}) => {
  return {lease, availableUnits};
})(LeaseCreation);
