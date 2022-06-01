import React from 'react';
import {connect} from 'react-redux';
import {Input, Button, InputGroup, InputGroupAddon, ButtonDropdown, DropdownToggle} from 'reactstrap';
import {DropdownMenu, DropdownItem, Modal, ListGroup, ListGroupItem} from 'reactstrap';
import Account from './account';
import NewAccountModal from './newAccountModal';
import {capitalize} from "../../../utils";
import actions from "../actions";

class Grouping extends React.Component {
  state = {changeGroup: []};

  changeName({target: {value}}) {
    const {group, onChange} = this.props;
    onChange(group.id, {...group, name: value});
  }

  changeAccount(index, {target: {name, value}}) {
    const {group, onChange, addToChangeAccount} = this.props;
    const {accounts, id} = group;
    accounts[index] = {...accounts[index], [name]: value};
    addToChangeAccount(value);
    onChange(id, {...group, accounts});
  }

  newChild(type) {
    const {group, onChange} = this.props;
    if (type === 'account') {
      group.accounts.push({id: 0});
    } else {
      const maxId = group.groups.reduce((max, g) => g.id >= max ? g.id + 1 : max, 0);
      group.groups.push({id: maxId, accounts: [], groups: []});
    }
    onChange(group.id, {...group});
  }

  childChange(id, params) {
    const {group, onChange} = this.props;
    const groups = group.groups.map(g => g.id === id ? params : g);
    onChange(group.id, {...group, groups});
  }

  parentChange(id, params) {
    const {parent, parentChange} = this.props;
    if (parent.id === id) {
      parentChange(parent.id, {...parent})
    } else {
      const groups = parent.groups.map(g => g.id === id ? params : g);
      parentChange(parent.id, {...parent, groups});
    }
  }

  onDelete(id) {
    const {group, onChange} = this.props;
    group.groups = group.groups.filter(g => g.id !== id);
    onChange(group.id, {...group});
  }

  deleteAccount(index) {
    const {group, onChange} = this.props;
    const {accounts, id} = group;
    accounts.splice(index, 1);
    onChange(id, {...group, accounts});
  }

  openTypeMenu() {
    this.setState({typeOpen: !this.state.typeOpen})
  }

  setGroupType(type) {
    const {group, onChange} = this.props;
    onChange(group.id, {...group, type});
  }

  moveUp(index) {
    if (index === 0) return;
    const {group, onChange} = this.props;
    const {accounts} = group;
    accounts.splice(index - 1, 0, accounts[index]);
    accounts.splice(index + 1, 1);
    onChange(group.id, {...group, accounts});
  }

  moveDown(index) {
    const {group, onChange} = this.props;
    const {accounts} = group;
    if (index === accounts.length - 1) return;
    const curr = accounts.splice(index, 1);
    accounts.splice(index + 1, 0, curr[0]);
    onChange(group.id, {...group, accounts});
  }

  moveGroupUp() {
    const {parentChange, group, parent} = this.props;
    let index = 0;
    parent.groups.forEach((g, i) => {
      if (g.id === group.id && g.name === group.name) index = i;
    });
    if (index - 1 >= 0) {
      parent.groups.splice(index - 1, 0, group);
      parent.groups.splice(index + 1, 1);
    }
    parentChange(parent.id, {...parent});
  }

  moveGroupDown() {
    const {parentChange, group, parent} = this.props;
    let index = 0;
    parent.groups.forEach((g, i) => {
      if (g.id === group.id && g.name === group.name) index = i;
    });
    if (index + 1 < parent.groups.length) {
      const curr = parent.groups.splice(index, 1);
      parent.groups.splice(index + 1, 0, curr[0]);
    }
    parentChange(parent.id, {...parent});
  }

  toggleModal() {
    this.setState({...this.state, modal: !this.state.modal});
  }

  changeGroup() {
    const arr = [];
    const {template, group} = this.props;
    if (!template.groups.length) return;
    const filtered = [];
    this.findGroup(template.groups, arr).forEach(g => {
      if (g.id === group.id && g.name === group.name) return;
      let containParent = false;
      g.groups.forEach(ig => {
        if (ig.id === group.id && ig.name === group.name) containParent = true;
      });
      if (containParent) return;
      filtered.push(g)
    });
    this.setState({...this.state, modal: true, changeGroup: filtered});
  }

  addGroup(cG) {
    const {template, group} = this.props;
    const newCG = {...cG};
    const newTemplate = {...template};
    if (this.containGroup(cG, group.groups)) {
      group.id = newCG.groups.length ? newCG.groups[newCG.groups.length - 1].id + 1 : 0;
      group["mark"] = true;
      const cGgroups = newCG.groups.splice();
      const newGroup = {...group};
      this.deleteGroup(cG, newGroup.groups);
      cGgroups.push(newGroup);
      newCG.groups = cGgroups;
      this.replace(cG, newTemplate.groups, newCG);
      this.toggleModal();
    } else {
      this.deleteGroup(group, newTemplate.groups);
      group.id = newCG.groups.length ? newCG.groups[newCG.groups.length - 1].id + 1 : 0;
      cG["mark"] = true;
      newCG.groups.push(group);
      this.replace(cG, newTemplate.groups, newCG);
    }
    actions.setTemplate(newTemplate);
  }

  containGroup(innerGroup, outerGroup) {
    let bool = false;
    outerGroup.forEach(g => {
      if (g.id === innerGroup.id && g.name === innerGroup.name) bool = true;
    });
    return bool;
  }

  replace(group, groups, replaced, tale = false) {
    if (tale) return groups;
    if (!groups || !groups.length) return;
    groups.forEach((g, i) => {
      if (g.mark) {
        groups[i] = replaced;
        this.replace(group, groups, replaced, true);
      } else {
        this.replace(group, g.groups, replaced)
      }
    });
    return groups;
  }

  deleteGroup(group, groups, tale = false) {
    if (tale) return groups;
    if (!groups || !groups.length) return;
    groups.forEach((g, i) => {
      if (g.id === group.id && g.name === group.name) {
        groups.splice(i, 1);
        this.deleteGroup(group, groups, true);
      } else {
        this.deleteGroup(group, g.groups)
      }
    });
    return groups;
  }

  findGroup(groups, arr) {
    if (!groups || !groups.length) return;
    groups.forEach(g => {
      arr.push(g);
      this.findGroup(g.groups, arr)
    });
    return arr;
  }

  newAccount() {
    this.setState({newAccount: !this.state.newAccount});
  }

  addNewAccount(account) {
    const {group, onChange} = this.props;
    group.accounts.push(account);
    onChange(group.id, {...group});
  }

  render() {
    const {group, accounts, template, addToChangeAccount} = this.props;
    const {typeOpen, newAccount, modal, changeGroup} = this.state;
    const accountsKey = {};
    const accountOpts = accounts.map(a => {
      accountsKey[a.id] = a;
      return group.accounts.some(ac => ac.id === a.id) ? null : {
        value: a.id,
        label: `${a.num ? a.num : ''} - ${a.name}`
      };
    }).filter(a => a);
    return <div className="mt-2 pb-2">
      <Modal isOpen={modal} toggle={this.toggleModal.bind(this)}>
        <ListGroup>
          {changeGroup.map((g, i) => {
            return <ListGroupItem onClick={this.addGroup.bind(this, g)} key={i}>{g.name}</ListGroupItem>
          })}
        </ListGroup>
      </Modal>
      <InputGroup>
        <InputGroupAddon addonType="prepend">
          <ButtonDropdown isOpen={typeOpen} toggle={this.openTypeMenu.bind(this)}>
            <DropdownToggle outline caret color="info" className="border border-right-0 rounded-0">
              {capitalize(group.type)}&nbsp;
            </DropdownToggle>
            <DropdownMenu>
              <DropdownItem onClick={this.setGroupType.bind(this, 'list')}>
                List
              </DropdownItem>
              <DropdownItem onClick={this.setGroupType.bind(this, 'aggregate')}>
                Aggregate
              </DropdownItem>
            </DropdownMenu>
          </ButtonDropdown>
        </InputGroupAddon>
        <Input value={group.name || ''} onChange={this.changeName.bind(this)}/>
        <InputGroupAddon addonType="append">
          <Button color="outline-info" disabled={group.accounts.some(a => !a)}
                  onClick={this.newChild.bind(this, 'account')}>
            Add Account
          </Button>
          <Button color="outline-info" disabled={group.accounts.some(a => !a)}
                  onClick={this.newAccount.bind(this)}>
            New Account
          </Button>
          <Button color="outline-info" onClick={this.changeGroup.bind(this)}>
            Change Group
          </Button>
          <Button color="outline-info" onClick={this.moveGroupUp.bind(this)}>
            <i className="fas fa-arrow-circle-up"/>
          </Button>
          <Button color="outline-info" onClick={this.moveGroupDown.bind(this)}>
            <i className="fas fa-arrow-circle-down"/>
          </Button>
          {group.type !== 'aggregate' && <Button color="outline-info" onClick={this.newChild.bind(this, 'group')}>
            Add Group
          </Button>}
          <Button color="outline-info"
                  onClick={this.deleteGroup.bind(this)}>
            Delete
          </Button>
        </InputGroupAddon>
      </InputGroup>
      <div className="pl-4">
        {group.accounts.map((a, i) => <div className="w-50 my-1" key={a.id}>
          <Account account={accountsKey[a.id]} accountOpts={accountOpts} moveUp={this.moveUp.bind(this, i)}
                   moveDown={this.moveDown.bind(this, i)}
                   deleteAccount={this.deleteAccount.bind(this, i)} addToChangeAccount={addToChangeAccount}
                   changeAccount={this.changeAccount.bind(this, i)}/>
        </div>)}
        {group.groups.map(g => <Group key={g.id} group={g} onDelete={this.onDelete.bind(this)}
                                      parent={group} addToChangeAccount={addToChangeAccount}
                                      parentChange={this.parentChange.bind(this)}
                                      template={template} onChange={this.childChange.bind(this)}/>
        )}
      </div>
      {newAccount && <NewAccountModal template={template} toggle={this.newAccount.bind(this)}
                                      onCreate={this.addNewAccount.bind(this)}/>}
    </div>
  }
}

const Group = connect(({accounts}) => {
  return {accounts};
})(Grouping);

export default Group;