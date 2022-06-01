import React from 'react';
import {Button, Col, Input, InputGroup, InputGroupAddon, Row} from "reactstrap";
import {toCurr} from "../../../../utils";
import actions from "../../actions";

const findCustomPackage = (lease, pkg) => {
  return pkg.custom_packages.find(cp => cp.lease_id === lease.id) || {
    lease_id: lease.id,
    renewal_package_id: pkg.id,
    amount: ''
  };
};

class RenewalPackage extends React.Component {
  constructor(props) {
    super(props);
    const {lease, pkg} = props;
    this.state = {customPackage: findCustomPackage(lease, pkg)};
  }

  componentWillReceiveProps(nextProps, nextContext) {
    if (nextProps.lease.id !== this.props.lease.id) {
      const {lease, pkg} = nextProps;
      this.setState({customPackage: findCustomPackage(lease, pkg)});
    }
  }

  save() {
    const {customPackage} = this.state;
    customPackage.id ? actions.updateCustomPackage(customPackage) : actions.createCustomPackage(customPackage);
  }

  change({target: {value}}) {
    this.setState({customPackage: {...this.state.customPackage, amount: value}});
  }

  render() {
    const {pkg, lease, threshold, locked} = this.props;
    const {customPackage} = this.state;
    const currentRent = lease.charges.find(c => ['Rent', 'HAPRent'].includes(c.account)).amount;
    const base = pkg.base === "Market Rent" ? lease.market_rent : currentRent;
    const newRent = pkg.dollar ? base + pkg.amount : base + (base * (pkg.amount / 100.0));
    const increase = (((customPackage.amount || newRent) / currentRent) - 1) * 100;
    return <Row className="w-100 align-items-center" style={{marginBottom: 2}}>
      <Col md={3}>
        <b>NEW RENT:</b> {toCurr(newRent)}
      </Col>
      <Col md={3}>
        <InputGroup>
          <Input style={{height: 'initial', padding: '0.125rem'}}
                 placeholder={locked ? 'No custom amount' : "Custom amount here"}
                 readOnly={locked}
                 onChange={this.change.bind(this)}
                 value={customPackage.amount}/>
          {!locked && <InputGroupAddon addonType="append">
            <Button color="success" size="sm" disabled={!customPackage.amount}
                    onClick={this.save.bind(this, pkg)}>
              <i className="fas fa-save"/>
            </Button>
          </InputGroupAddon>}
        </InputGroup>
      </Col>
      <Col md={3} className={`w-25 font-weight-bold text-${increase > threshold ? 'danger' : 'success'}`}>
        {increase.toFixed(1)}% increase
      </Col>
    </Row>;
  }
}

export default RenewalPackage;