import React from 'react';
import {Button, Input, Table, Row, Card, CardBody, CardHeader, Col} from 'reactstrap';
import moment from "moment";
import Check from '../../../../../components/fancyCheck';
import setLoading from "../../../../../components/loading";
import {toCurr} from '../../../../../utils';
import actions from "../../../actions";

class ProrateCharges extends React.Component {

  state={open: false, charges: [], checked: []}

  toggle(){
    this.setState({open: !this.state.open})
  }

  toggleCheck(id){
    let checked = this.props.charges.map(c => c.id);
      if (checked.includes(id)) {
        checked.splice(checked.findIndex(c => c == id), 1)
      }
      else {
        checked.push(id)
      }
      const charges = checked.map(ch => {
        let c = this.state.charges.find(c => c.charge.id == ch)
        return {amount: c.amount,
          status: "reversal", description: `prorated charge ${c.charge.id}`, id: c.charge.id, account_id: c.charge.account_id}
      })
    this.props.change({target: {name: 'charges', value: charges}})
  }

  change({target: {value}}, i) {
    let {charges} = this.state;
    charges.splice(i, 0, {...charges[i], amount: value})
    this.setState({[name]: value});
  }

  componentDidMount(){
    this.fetchProratedCharges()
  }

  componentDidUpdate(prevProps){
    if (prevProps.actualMoveOut != this.props.actualMoveOut){
      this.fetchProratedCharges()
    }
  }

  fetchProratedCharges(){
    setLoading(true);
    actions.prorateLease(this.props.leaseId, moment(this.props.actualMoveOut).format('YYYY-MM-DD'))
    .then((r) => this.setState({charges: r.data}))
    .finally(() => setLoading(false))
  }

  render() {
    const {open, amount, charges} = this.state;
    const checked = this.props.charges.map(c => c.id)
    const headers = ["Date", "Post Month", "Account", "Notes", "Amount", "Prorated Amount"]
    return <><Button onClick={this.toggle.bind(this)} color='link'>Prorate Lease Charges <i className={open ? 'fas fa-chevron-down' : 'fas fa-chevron-right'}></i></Button>
  {open && <Row>
    <Col>
    <Card>
      <CardHeader>Select charges to prorate.</CardHeader>
      <CardBody>
    <Table>
          <thead>
            <tr>
            {headers.map((h, i) => <th key={i}>{h}</th>)}
          </tr>
          </thead>
          <tbody>
      {charges.map(({charge, amount}, i) => (<tr key={charge.id}>
        <td>{moment(charge.bill_date).format('MM/DD/YYYY')}</td>
        <td className="text-center">{moment(charge.post_month).format('MM/YYYY')}</td>
        <td>
          {charge.description}
        </td>
        <td>{charge.account}</td>
        <td>{toCurr(charge.amount)}</td>
        <td>
          <Input className='text-danger' onChange={this.change.bind(this, i)} value={(amount.toFixed(2))}/>
        </td>
        <td><Check type='checkbox' onChange={this.toggleCheck.bind(this, charge.id)} checked={checked.includes(charge.id)}/></td>
      </tr>)
    )}
    </tbody>
  </Table>
</CardBody>
  </Card>
  </Col>
</Row>
}
    </>
  }
}

export default ProrateCharges;
