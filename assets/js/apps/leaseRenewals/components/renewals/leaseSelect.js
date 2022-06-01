import React from 'react';
import Select from "../../../../components/select";
import {toCurr} from "../../../../utils";

const leaseOptions = (period) => period.leases.map(l => {
  const currentRent = l.charges.find(c => ['Rent', 'HAPRent'].includes(c.account)).amount;
  l.overThreshold = period.packages.some(p => {
    const base = p.base === "Market Rent" ? l.market_rent : currentRent;
    const newRent = p.dollar ? base + p.amount : base + (base * (p.amount / 100.0));
    const custom = p.custom_packages.find(cp => cp.lease_id === l.id) || {amount: ''};
    const increase = (((custom.amount || newRent) / currentRent) - 1) * 100;
    return increase > period.threshold;
  });
  return {
    value: l.id,
    filterVal: `${l.tenants[0].name} ${l.unit}`,
    label: <div className={`d-flex text-${l.overThreshold ? 'danger' : ''}`}>
      <div className="w-100">
        {l.tenants[0].name}({l.unit})
      </div>
      <div className="text-center w-100">
        <b>Current Rent:</b> {toCurr(currentRent)}
      </div>
      <div className="mr-2 text-right w-100"><b>Market Rent:</b> {toCurr(l.market_rent)}</div>
    </div>
  };
});

const leaseFilter = ({data: {filterVal}}, val) => {
  const regex = new RegExp(val, 'i');
  return regex.test(filterVal);
};

class LeaseSelect extends React.Component {
  state = {};

  render() {
    const {period, lease, onChange} = this.props;
    const options = leaseOptions(period);
    const numOverThreshold = period.leases.filter(l => l.overThreshold).length;
    return <div className="labeled-box">
      <Select options={options}
              filterOption={leaseFilter}
              styles={{
                singleValue(provided) {
                  return {...provided, width: '100%'}
                }
              }}
              value={lease && lease.id} onChange={onChange}/>
      <div className="labeled-box-label">{numOverThreshold} Need Customization</div>
    </div>;
  }
}

export default LeaseSelect;