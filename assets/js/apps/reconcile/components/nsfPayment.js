import React, {Component} from 'react';
import FancyCheck from '../../../components/fancyCheck'
import {toCurr} from "../../../utils";
import DatePicker from "../../.././components/datePicker";
import {Input} from 'reactstrap'
import moment from 'moment'

class NSFPayment extends Component {

  render() {
    const {data, end_date} = this.props;
    return <tr>
      <td>{moment(data.date).format("MM/DD/YY")}</td>
      <td></td>
      <td>
        <DatePicker initialVisibleMonth={() => moment(data.date)} clearable value={data.clear_date} name="clear_date"
                    onChange={(e) => this.props.change(e, data)}
        />
      </td>
      <td>{data.type == "nsf_payment" ? 'NSF Payment' : 'Old Payment'}</td>
      <td></td>
      <td>{toCurr(data.amount)}</td>
      <td></td>
      <td><Input value={data.memo || ''} name='memo' onChange={(e) => this.props.change(e, data)}/></td>
      <td style={{backgroundColor: data.reconciled ? 'rgba(39, 134, 40, 0.39)' : null}}>
        <div className='d-flex justify-content-center align-items-center'>
          <FancyCheck inline checked={data.reconciled} name='reconciled'
                      onChange={(e) => this.props.change(e, {
                        ...data,
                        clear_date: !data.reconciled ? (data.clear_date || moment(data.date)) : null
                      })}/>
        </div>
      </td>
    </tr>
  }

}

export default NSFPayment;
