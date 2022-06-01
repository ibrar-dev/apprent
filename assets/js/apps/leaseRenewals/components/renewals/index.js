import React, {Component} from 'react';
import {connect} from 'react-redux';
import PropertySelect from '../../../../components/propertySelect';
import actions from "../../actions";
import Pagination from '../../../../components/pagination';
import Period from "./period";
import PeriodModal from "./periodModal";
import canEdit from "../../../../components/canEdit";
import RegionalReport from "./regionalReport";
import {Modal, ModalBody, Button, ModalFooter} from 'reactstrap';
import {toCurr} from "../../../../utils";
import Checkbox from "../../../../components/fancyCheck/index";

const headers = [
  {label: '', min: true},
  {label: "Range", min: true},
  {label: "Leases"},
  {label: "Approval", min: true},
  {label: '', min: true}
];

class Renewals extends Component {
  state = {noRenewalIds: {}};

  addNoRenewal(id){
    const newIds = {...this.state.noRenewalIds};
    if(newIds[id]) delete newIds[id];
    else newIds[id] = true
    this.setState({noRenewalIds: newIds});
  }

  toggle(field){
    this.setState({[field]: !this.state[field]});
  }

  updateLease(){
    const {noRenewalIds} = this.state;
    actions.updateLeases(Object.keys(noRenewalIds)).then(() => {
      this.setState({noRenewals: false})
    });
  }

  render() {
    const {property, properties, periods} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    const {newPeriod, noRenewals, noRenewalIds} = this.state;
    return <>
      {canEdit(["Super Admin", "Regional"]) && <RegionalReport/>}
      <Pagination collection={periods}
                  component={Period}
                  headerClassName="p-1"
                  title={<div>
                    <PropertySelect properties={properties} onChange={actions.viewProperty} property={property}/>
                  </div>}
                  className="h-100 border-left-0 rounded-0"
                  menu={[
                    {title: 'New Period', onClick: this.toggle.bind(this, "newPeriod")}
                  ]}
                  headers={headers}
                  filters={<div><Button outline onClick={this.toggle.bind(this, "noRenewals")}>Edit Renewal Status</Button></div>}
                  field="period"/>
      {newPeriod && <PeriodModal toggle={this.toggle.bind(this, "newPeriod")}/>}
      <Modal size="lg" isOpen={noRenewals} toggle={this.toggle.bind(this, "noRenewals")}>
        <div className="d-flex w-100 align-items-center justify-content-between" style={{padding: 16, minHeight: 50, fontSize: 18, borderBottom: "1px solid #DEE2E6", color: "#383E4B"}}>
          <div>No Renewals</div>
          <div><Button outline onClick={this.updateLease.bind(this)}>Do Not Renew</Button></div>
        </div>
        <ModalBody>
          {periods.map(p => {
            return <div>
              <div className="mt-2 mb-1"><strong>{p.start_date} - {p.end_date}</strong></div>
                  {p.leases.map(l => {
                    const currentRent = l.charges.find(c => ['Rent', 'HAPRent'].includes(c.account)).amount;
                    return <div className="d-flex mb-1">
                      <Checkbox checked={noRenewalIds[l.id]} onChange={this.addNoRenewal.bind(this, l.id)}/>
                      <div className="w-100 ml-1">
                          {l.tenants[0].name}({l.unit})
                      </div>
                      <div className="text-center w-100">
                        <b>Current Rent:</b> {toCurr(currentRent)}
                      </div>
                      <div className="mr-2 text-right w-100"><b>Market Rent:</b> {toCurr(l.market_rent)}</div>
                  </div>
                  })}
            </div>
          })}
        </ModalBody>
        <ModalFooter>
          <Button outline onClick={this.updateLease.bind(this)}>Do Not Renew</Button>
        </ModalFooter>
      </Modal>
    </>;
  }
}

export default connect(({property, properties, report, periods}) => {
  return {property, properties, periods, report}
})(Renewals)
