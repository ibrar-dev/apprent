import React from 'react';
import {connect} from 'react-redux';
import moment from 'moment';
import {Button, Tooltip} from 'reactstrap';
import CheckModal from './checkModal';
import {numToLang, toCurr} from '../../../utils';
import actions from '../actions';
import CheckBox from '../../../components/fancyCheck'

class Check extends React.Component {
  state = {toolTip: {}};

  toggleSelect({target: {checked}}) {
    const {check} = this.props;
    const func = checked ? 'selectCheck' : 'unselectCheck';
    actions[func](check);
  }

  view() {
    this.setState({...this.state, view: !this.state.view});
  }
  
  openToolTip(id){
    const toolTip = this.state.toolTip;
    toolTip[id] ? delete toolTip[id] : toolTip[id] = true;
    this.setState({...this.state, toolTip: toolTip});
  }

  render() {
    const {check, selectedChecks} = this.props;
    const isSelected = selectedChecks.some(s => s.id === check.id);
    const {view, toolTip} = this.state;
    return <tr>
      <td className="align-middle">
        <CheckBox checked={isSelected} onChange={this.toggleSelect.bind(this)}/>
      </td>
      <td className="align-middle">
        {!check.document_url && <>
          <i id={`check${check.id}`} onClick={this.openToolTip.bind(this, check.id)} className="fas fa-exclamation-circle text-danger"/>
          <Tooltip target={`check${check.id}`} placement={"right"} isOpen={toolTip[check.id]} toggle={this.openToolTip.bind(this, check.id)} >
            This check is not yet available for multiple printing. Please view and print document with the view/print button first.
          </Tooltip>
        </>}
        <i className={`fas fa-${check.printed ? 'print' : ''}`} />
      </td>
      <td className="align-middle">
        {check.number}
      </td>
      <td className="align-middle">
        {check.payee}
      </td>
      <td className="align-middle">
        {toCurr(check.amount)}
      </td>
      <td className="align-middle">
        {check.bank_account.name}
      </td>
      <td className="align-middle">
        {moment(check.date).format('MM/DD/YYYY')}
      </td>
      <td className="align-middle">
        <Button onClick={this.view.bind(this)} color="outline-info">
          View/Print
        </Button>
      </td>
      {view && <CheckModal check={check} toggle={this.view.bind(this)}/>}
    </tr>;
  }
}

export default connect(({selectedChecks}) => {
  return {selectedChecks};
})(Check);