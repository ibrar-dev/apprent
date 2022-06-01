import React from 'react';
import {connect} from 'react-redux';
import {Card, CardHeader, CardBody, CardFooter, Button, Input, Row, Col} from 'reactstrap';
import {InputGroup, InputGroupAddon, ButtonDropdown, DropdownToggle, DropdownMenu, DropdownItem} from 'reactstrap';
import Group from './group';
import actions from '../actions';
import ConfirmationModal from './confirmationModal';

class TemplateForm extends React.Component {
  state = {
    changedAccounts: []
  };

  addToChangedAccounts(a) {
    const {changedAccounts} = this.state;
    if (!changedAccounts.includes(a)) changedAccounts.push(a);
    this.setState({...this.state, changedAccounts: changedAccounts})
  }

  change({target: {name, value}}) {
    actions.setTemplate({...this.props.template, [name]: value});
  }

  toggleConfirmationModal() {
    const {changedAccounts} = this.state;
    if (changedAccounts.length) {
      return this.setState({...this.state, confirmationModal: !this.state.confirmationModal});
    } else {
      return this.save();
    }
  }

  save() {
    actions.saveTemplate(this.props.template).then(actions.setTemplate.bind(null, null));
  }

  newGroup() {
    const {template: {groups}} = this.props;
    const maxId = groups.reduce((max, g) => g.id >= max ? max + 1 : max, 0);
    this.change({
      target: {
        name: 'groups',
        value: groups.concat([{id: maxId, type: 'list', groups: [], accounts: []}])
      }
    });
  }

  openTypeMenu() {
    this.setState({typeMenu: !this.state.typeMenu});
  }

  childChange(id, params) {
    const {template} = this.props;
    const groups = template.groups.map(g => g.id === id ? params : g);
    actions.setTemplate({...template, groups});
  }

  parentChange(id, params){
    const {template} = this.props;
    if(template.id === id){
      actions.setTemplate({...template, params});
    }else{
      const groups = template.groups.map(g => g.id === id ? params : g);
      actions.setTemplate({...template, groups})
    }
  }

  onDelete(id) {
    const {template} = this.props;
    const groups = template.groups.filter(g => g.id !== id);
    actions.setTemplate({...template, groups});
  }

  render() {
    const {template, accounts} = this.props;
    const {typeMenu, changedAccounts, confirmationModal} = this.state;
    const change = this.change.bind(this);
    return <Card>
      <CardHeader className="d-flex justify-content-between align-items-center">
        <div>{template.name || 'New'} Template</div>
        <Button size="sm" className="m-0" onClick={actions.setTemplate.bind(null, null)} color="danger">
          <i className="fas fa-arrow-circle-left"/> Back
        </Button>
      </CardHeader>
      <CardBody>
        <Row className="mb-4">
          <Col>
            <InputGroup>
              <InputGroupAddon addonType="prepend">
                <ButtonDropdown isOpen={typeMenu} toggle={this.openTypeMenu.bind(this)}>
                  <DropdownToggle outline caret color="info" className="border border-right-0 rounded-0">
                    {template.is_balance ? 'Balance' : 'Income'}&nbsp;
                  </DropdownToggle>
                  <DropdownMenu>
                    <DropdownItem onClick={this.change.bind(this, {target: {name: 'is_balance', value: false}})}>
                      Income
                    </DropdownItem>
                    <DropdownItem onClick={this.change.bind(this, {target: {name: 'is_balance', value: true}})}>
                      Balance
                    </DropdownItem>
                  </DropdownMenu>
                </ButtonDropdown>
              </InputGroupAddon>
              <Input bsSize="lg" onChange={change} name="name" value={template.name || ''}/>
            </InputGroup>
          </Col>
        </Row>
        {template.groups.map(g => <Group key={g.id}
                     template={template}
                     parent={template}
                     onDelete={this.onDelete.bind(this)}
                     onChange={this.childChange.bind(this)}
                     parentChange={this.parentChange.bind(this)}
                     addToChangeAccount={this.addToChangedAccounts.bind(this)}
                     group={g}/>
        )}
        <Button color="success" onClick={this.newGroup.bind(this)}>
          <i className="fas fa-plus-circle"/> New Group
        </Button>
      </CardBody>
      <CardFooter className="text-right">
        <Button color="success" onClick={this.toggleConfirmationModal.bind(this)}>
          Save
        </Button>
      </CardFooter>
      {confirmationModal && <ConfirmationModal changedAccounts={changedAccounts} toggle={this.toggleConfirmationModal.bind(this)} save={this.save.bind(this)} accounts={accounts} />}
    </Card>
  }
}

export default connect(({accounts}) => {
  return {accounts};
})(TemplateForm);