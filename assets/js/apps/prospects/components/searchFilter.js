import React from 'react';
import {Input, Row} from 'reactstrap';

class FilterInput extends React.Component {
  state = {};

  render() {
    const {updateFilter, filterValue} = this.props;
    return <Input className="border-right-0 btn-no-outline"
                  onChange={updateFilter.bind(this)}
                  placeholder="Search"
                  value={filterValue}/>;
  }
}

export default FilterInput;