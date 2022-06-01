import React from "react";
import {withRouter} from "react-router-dom";
import {Button, Popover, PopoverHeader, PopoverBody} from 'reactstrap';
import moment from 'moment';
import canEdit from '../../../components/canEdit';
import actions from "../actions";
import {toCurr} from '../../../utils';
import confirmation from "../../../components/confirmationModal";
import Leases from './leases';

class Unit extends React.Component {
  state = {};

  togglePopover(e) {
    e.stopPropagation();
    this.setState({...this.state, popoverOpen: !this.state.popoverOpen});
  }

  hardDelete(e) {
    e.stopPropagation();
    this.timer = setTimeout(() => {
      confirmation('Completely delete this unit? Are you sure you want to remove this unit? Please do not do this lightly.').then(() => {
        actions.deleteUnit(this.props.unit.id);
      })
    }, 2000);
  }

  invalidateTimer() {
    clearTimeout(this.timer);
  }

  render() {
    const {unit, history} = this.props;
    // const chargeSum = unit.default_charges.reduce((sum, c) => c.price + sum, 0);
    const leases = new Leases(this.props);
    const {current, future, mtm, renewal, past} = leases.leases;
    return (
      <tr className="link-row"
          onClick={() => history.push(`/units/${unit.id}`)}
      >
        <td className="align-middle text-center" onClick={e => e.stopPropagation()}>
          {canEdit(["Super Admin"]) && <a onMouseDown={this.hardDelete.bind(this)}
                                          onMouseUp={this.invalidateTimer.bind(this)}>
            <i className="fas fa-times text-danger"/>
          </a>}
        </td>
        <td className="align-middle">
          <h4 className="m-0">{unit.number}</h4>
        </td>
        <td className="align-middle">
          {unit.floor_plan}
        </td>
        <td className="align-middle">
          {toCurr(unit.market_rent)}
          {/*{unit.default_charges.length > 0 && ` (+${toCurr(chargeSum)})`}*/}
        </td>
        <td>
          {unit.unit_status}
        </td>
        <td className={`align-middle `}>
          {current && <a href={`/tenants/${current.tenants[0].id}`} className={current.haprent ? 'text-warning' : ''} onClick={e => e.stopPropagation()}>
            <div>
              {current.tenants.map(t => <div key={t.id}>{t.first_name} {t.last_name}</div>)}
              <div>{current.start_date} to {current.end_date}</div>
              {current.move_out_date && <div><b>Move Out:</b>{current.move_out_date}</div>}
              {!current.move_out_date && renewal && <div><b>Renewal: </b>{renewal.end_date}</div>}
            </div>
          </a>}
          {!current && mtm && <a href={`/tenants/${mtm.tenants[0].id}`} className={mtm.haprent ? 'text-warning' : ''} onClick={e => e.stopPropagation()}>
            <div>
              {mtm.tenants.map(t => <div key={t.id}>{t.first_name} {t.last_name}</div>)}
              <div>{mtm.first_name} {mtm.last_name}</div>
              <div>{mtm.start_date} to {mtm.end_date}</div>
              {<div><b>MTM AS OF:</b> {mtm.end_date}</div>}
              {renewal && <div><b>Renewal: </b>{renewal.end_date}</div>}
            </div>
          </a>}
          {!current && !mtm && 'None'}
        </td>
        <td className="align-middle">
          {future.map(l => <a key={l.id} href={`/tenants/${l.tenant_id}`} onClick={e => e.stopPropagation()}>
            {l.first_name} {l.last_name}
            <br/>
            {l.start_date} to {l.end_date}
          </a>)}
        </td>
        <td className="align-middle">
          {leases.dropdown(past, this.togglePopover.bind(this), 'Popover-' + unit.id, this.state.popoverOpen)}
        </td>
      </tr>
    )
  }
}

export default withRouter(Unit);
