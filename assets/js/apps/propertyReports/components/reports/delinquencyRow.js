import React from 'react';
import {toCurr, titleize} from "../../../../utils";
import {Button, Input, InputGroup, InputGroupAddon, Popover, PopoverHeader, PopoverBody, ListGroup, ListGroupItem} from "reactstrap";
import actions from "../../actions";
import moment from 'moment';

class DelinquencyRow extends React.Component {
  state = {
    memos: false
  };

  saveInteraction() {
    const {data, propertyId} = this.props;
    actions.saveInteraction(data.tenant_id, this.state.memo, propertyId);
    this.setState({memo: ''})
  }

  updateDescription({target: {value}}) {
    this.setState({memo: value});
  }

  togglePopover() {
    const {data} = this.props;
    if (data.memos.length) this.setState({...this.state, memos: !this.state.memos})
  }

  getTotal() {
    const {itemized} = this.props;
    return itemized.reduce((c, acc) => acc + c, 0)
  }

  render() {
    const {data, itemized} = this.props;
    const {memo, memos} = this.state;
    return <>
      <tr>
        <td>{data.unit}</td>
        <td><a target="_blank" href={`/tenants/${data.tenant_id}`}>{data.tenant_id}</a></td>
        <td>{data.tenant}</td>
        <td>{titleize(data.status)}</td>
        <td>{toCurr(this.getTotal())}</td>
        {/*<td>{toCurr(data.owed)}</td>*/}
        <td>{toCurr(itemized[0])}</td>
        <td>{toCurr(itemized[1])}</td>
        <td>{toCurr(itemized[2])}</td>
        <td>{toCurr(itemized[3])}</td>
      </tr>
      <tr>
        <td className="border-0 p-0" colSpan={9}/>
      </tr>
      <tr>
        <td className="border-0 p-0">
          <div id={`memo_${data.tenant_id}_popover`} className="ml-2 cursor-pointer" onClick={this.togglePopover.bind(this)}>
            Memos <span className="badge badge-info">{data.memos.length}</span>
          </div>
          <Popover trigger="click" placement="top-start" isOpen={memos} target={`memo_${data.tenant_id}_popover`} toggle={this.togglePopover.bind(this)}>
            <PopoverHeader>
              Previous Delinquency Memos
            </PopoverHeader>
            <PopoverBody>
              <ListGroup>
                {data.memos.length && data.memos.map(m => {
                  return <ListGroupItem key={m.id} className="d-flex flex-column">
                    <small className="d-flex justify-content-between"><span>{moment(m.inserted_at).format("M/D/YY h:mm")}</span><span>{m.admin}</span></small>
                    <span>{m.description}</span>
                  </ListGroupItem>
                })}
              </ListGroup>
            </PopoverBody>
          </Popover>
        </td>
        <td className="border-0 pt-0" colSpan={8}>
          <InputGroup>
            <Input className="h-auto" onChange={this.updateDescription.bind(this)} value={memo || ''}
                   placeholder="Memo"/>
            <InputGroupAddon addonType="append">
              <Button outline color="info" disabled={!memo} onClick={this.saveInteraction.bind(this)}>Save</Button>
            </InputGroupAddon>
          </InputGroup>
        </td>
      </tr>
    </>;
  }
}

export default DelinquencyRow;