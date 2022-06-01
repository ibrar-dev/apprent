import React from 'react';
import moment from 'moment';
import {toCurr} from '../../../utils';

class Refund extends React.Component {
  state = {};

  render() {
    const {refund} = this.props;
    const {payment} = refund;
    return <tr>
      <td/>
      <td/>
      <td>{moment(refund.date).format('MM/DD/YYYY')}</td>
      <td className="text-center">{moment(refund.time).format('MM/YYYY')}</td>
      <td>
        Refund for {payment.description} {(payment.description === 'Check' || payment.description === 'Money Order') && `#${payment.transaction_id}`}
      </td>
      <td>
        -{toCurr(payment.amount)}
      </td>
      <td/>
      <td>
        {refund.admin}
      </td>
    </tr>
  }
}

export default Refund;