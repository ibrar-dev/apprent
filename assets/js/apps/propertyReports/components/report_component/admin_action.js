import React, {Component} from 'react'
import moment from 'moment'
import {toCurr} from '../../../../utils'
import Payment from '../../../payments/components/show'

function Action(props){
  const {action} = props;
  switch (action.type) {
    case "payment":
      return <tr>
        <td>{moment(action.inserted_at).format('MM-DD-YYYY')}</td>
        <td>Payment</td>
        <td>{action.description}</td>
        <td>{toCurr(action.amount)}</td>
        <td><a href={`/tenants/${action.tenant_id}`} target='_blank'>{action.tenant}</a></td>
        <td><a href={`/payments/${action.id}`} target='_blank' style={{color:"#38a250", marginLeft:10}}>Go to payment <i className="fas fa-arrow-right"></i></a></td>
      </tr>
      break;
      case "charge":
        return <tr>
          <td>{moment(action.inserted_at).format('MM-DD-YYYY')}</td>
          <td>{action.amount >= 0 ? "Charge" : "Concession"}</td>
          <td style={{maxWidth: 200, overflow: 'scroll'}}>{[action.account, action.description].filter(x => x).join(' - ')}</td>
          <td>{toCurr(action.amount)}</td>
            <td><a href={`/tenants/${action.tenant_id}`} target='_blank'>{action.tenant}</a></td>
        </tr>
        break;
  }
}

export default Action;
