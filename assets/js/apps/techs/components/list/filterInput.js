import React from 'react';
import {Input, InputGroupButtonDropdown, InputGroup, InputGroupAddon, DropdownToggle, DropdownMenu, DropdownItem} from 'reactstrap';

class FilterInput extends React.Component {
  state = {};

  toggleOptions() {
    this.setState({...this.state, options: !this.state.options});
  }

  render() {
    const {updateFilterBy, updateFilter, filterType, filterValue} = this.props;
    return (
      <InputGroup>
        <InputGroupButtonDropdown addonType="prepend" isOpen={this.state.options}
                                  toggle={this.toggleOptions.bind(this)}>
          <DropdownToggle caret className="bg-white" color="white"
                          style={{border: '1px solid #e4e6eb'}}>
            {filterType === 'name' ? 'Tech Name' : 'Property Name'}
          </DropdownToggle>
          <DropdownMenu>
            <DropdownItem onClick={updateFilterBy.bind(this, 'name')}>
              Tech Name
            </DropdownItem>
            <DropdownItem onClick={updateFilterBy.bind(this, 'property')}>
              Property Name
            </DropdownItem>
          </DropdownMenu>
        </InputGroupButtonDropdown>
        <Input className="border-right-0" onChange={updateFilter.bind(this)} style={{border: '1px solid #e4e6eb'}}
               value={filterValue}/>
        <InputGroupAddon addonType="append">
          <i className="fas fa-search text-muted input-group-text bg-white border-left-0 d-flex align-items-center"/>
        </InputGroupAddon>
      </InputGroup>
    )
  }
}

export default FilterInput;