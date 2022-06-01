import React, {Component} from 'react';
import FancyCheck from '../../../components/fancyCheck'
import {toCurr} from "../../../utils";
import DatePicker from "../../.././components/datePicker";
import {Input, Collapse} from 'reactstrap'
import moment from 'moment'

class Deposit extends Component {

  state = {
    isOpen: false
  }

  toggle() {
    this.setState({isOpen: !this.state.isOpen})
  }

  render() {
    const {data, end_date} = this.props
    return <>
      <tr onClick={this.toggle.bind(this)}>
        <td>{moment(data.date).format("MM/DD/YY")}</td>
        <td align="center">{data.type == "batch" ? data.ref : null}</td>
        <td>
          <DatePicker clearable value={data.clear_date}
            initialVisibleMonth={() => moment(data.date)}
                      name="clear_date"
                      onChange={(e) => this.props.change(e, data)}
          />
        </td>
        <td>{data.type == "batch" ? 'Deposit' : data.type == "journal_income" ? "Journal Entry Income" : null}</td>
        <td></td>
        <td></td>
        <td>{toCurr(data.amount)}</td>
        <td><Input value={data.memo || ''} name='memo' onChange={(e) => this.props.change(e, data)}/></td>
        <td style={{backgroundColor: data.reconciled ? 'rgba(39, 134, 40, 0.39)' : null, width: 150}}>
          <div className='d-flex justify-content-center align-items-center'>
            <FancyCheck inline checked={data.reconciled} name='reconciled'
                        onChange={(e) => this.props.change(e, {
                          ...data,
                          clear_date: !data.reconciled ? (data.clear_date || moment(data.date)) : null
                        })}/>
          </div>
        </td>
      </tr>
      {this.state.isOpen && data.type == 'batch' && <tr>
        <td colSpan="8">
          <table style={{width: "100%"}}>
            <thead>
            <tr>
              <th style={{padding: 5, fontSize: 12}}> Payer</th>
              <th style={{padding: 5, fontSize: 12}}> Amount</th>
              <th style={{padding: 5, fontSize: 12}}> Type</th>
              <th style={{padding: 5, fontSize: 12}}> Deposit ID</th>
              <th style={{padding: 5, fontSize: 12}}> Check #</th>
            </tr>
            </thead>
            <tbody>
            {data.payments.map((x, i) => {
              return <tr style={{listStyle: "none"}} key={i}>
                {/*<small className="muted">{x.description} - {toCurr(x.amount)}</small>*/}
                <td style={{padding: 5, fontSize: 12}}><a>{x.payer}</a></td>
                <td style={{padding: 5, fontSize: 12}}> {toCurr(x.amount)} </td>
                <td style={{padding: 5, fontSize: 12}}> {x.description} </td>
                <td style={{padding: 5, fontSize: 12}}> {data.id} </td>
                <td style={{padding: 5, fontSize: 12}}> {x.transaction_id} </td>
              </tr>
            })}
            </tbody>
          </table>
        </td>
      </tr>}
    </>
  }

}

export default Deposit;
