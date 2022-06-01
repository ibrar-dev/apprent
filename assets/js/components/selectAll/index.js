import React from 'react';
import Checkbox from '../fancyCheck';
import {Dropdown, DropdownToggle, DropdownMenu, DropdownItem} from 'reactstrap';

class SelectAll extends React.Component {
  state = {selected: false};

  toggle() {
    this.setState({isOpen: !this.state.isOpen});
  }

  changeSelection(select) {
    if (select.type) {
      const {selected, indeterminate} = this.currentState();
      this.props.onChange(indeterminate ? false : !selected);
    } else {
      this.props.onChange(select);
    }
  }

  currentState() {
    const list = this.props.list || [];
    let selected = list.length > 0;
    let indeterminate = false;
    list.forEach(item => item.checked ? (indeterminate = true) : (selected = false));
    return {selected, indeterminate};
  }

  render() {
    const {isOpen} = this.state;
    const {selected, indeterminate} = this.currentState();
    return <Dropdown isOpen={isOpen} toggle={this.toggle.bind(this)} className="d-flex">
      <Checkbox inline checked={selected} onChange={this.changeSelection.bind(this)} indeterminate={indeterminate}/>
      <DropdownToggle caret color="white" className="px-1 py-0"/>
      <DropdownMenu>
        <DropdownItem onClick={this.changeSelection.bind(this, true)}>Select All</DropdownItem>
        <DropdownItem onClick={this.changeSelection.bind(this, false)}>Deselect All</DropdownItem>
      </DropdownMenu>
    </Dropdown>
  }
}

export default SelectAll;