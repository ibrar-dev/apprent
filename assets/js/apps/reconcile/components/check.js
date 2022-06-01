import React, {Component} from 'react';
import FancyCheck from '../../../components/fancyCheck'
import {toCurr} from "../../../utils";
import DatePicker from "../../.././components/datePicker";
import moment from 'moment'

import {Input} from 'reactstrap'
class Check extends Component {

    render() {
        const {data} = this.props
        return <tr>
            <td>{moment(data.date).local().format("MM/DD/YY")}</td>
            <td align="center">{data.type == "check" ? data.ref : null}</td>
            <td>
                <DatePicker clearable initialVisibleMonth={() => moment(data.date)} value={data.clear_date} name="clear_date"
                            onChange={(e) => this.props.change(e, data)}
                />
            </td>
            <td>{data.type == "check" ? 'Check' : data.type == "journal_expense" ? "Journal Entry Expense" : null}</td>
            <td>{data.payee}</td>
            <td>{toCurr(data.amount)}</td>
            <td></td>
            <td><Input value={data.memo || ''} name='memo' onChange={(e) => this.props.change(e, data)}/></td>
            <td style={{backgroundColor: data.reconciled ? 'rgba(39, 134, 40, 0.39)' : null}}>
                <div className='d-flex justify-content-center align-items-center'>
                    <FancyCheck inline checked={data.reconciled} name='reconciled'
                                onChange={(e) => this.props.change(e, {...data, clear_date: !data.reconciled ? (data.clear_date || moment(data.date)) : null})}/>
                </div>
            </td>
        </tr>
    }

}

export default Check;
