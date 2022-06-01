import React from 'react'
import {Badge} from 'reactstrap'

function PayeeGroup(props) {
  const {name, num_of_invoices} = props.invoice;
  return <tr style={{backgroundColor: 'gainsboro'}}>
    <td colSpan='11' className="align-middle p-0 border-0">
      <div className='d-flex justify-content-center'>
        <span className='text-success'>{name}</span>
        <div className="d-flex align-items-center px-3">
          <Badge color='light'>{num_of_invoices}</Badge>
        </div>
      </div>
    </td>
  </tr>
}

export default PayeeGroup;
