import React, {Component} from 'react';
import {Row, Col, Table} from 'reactstrap';
import {toCurr} from "../../../../utils";
import moment from 'moment';

class Receipts extends Component {
  state = {};

  infoToDisplay({account, charge}) {
    if (charge) {
      return <React.Fragment>
        <td>{charge.charge_code}</td>
        <td>{charge.account_num}</td>
        <td>{moment(charge.bill_date).format("MM/DD/YY")}</td>
        <td>{toCurr(charge.amount)}</td>
        <td>{toCurr(charge.unpaid)}</td>
        <td>{charge.description}</td>
      </React.Fragment>
    } else if (account) {
      return <React.Fragment>
        <td>{account.description}</td>
        <td>{account.account_num}</td>
        <td/>
        <td/>
        <td/>
        <td/>
      </React.Fragment>
    }
  }

  render() {
    const {receipts} = this.props;
    return <Row>
      <Col>
        <Table striped bordered>
          <thead>
            <tr>
              <th>Paid</th>
              <th>Charge Code</th>
              <th>Account Number</th>
              <th>Charge Date</th>
              <th>Charge Amount</th>
              <th>Unpaid</th>
              <th>Notes</th>
            </tr>
          </thead>
          <tbody>
          {receipts && receipts.map(r => {
            return <tr key={r.id}>
              <td>{toCurr(r.amount)}</td>
              {this.infoToDisplay(r)}
            </tr>
          })}
          </tbody>
        </Table>
      </Col>
    </Row>
  }
}

export default Receipts;