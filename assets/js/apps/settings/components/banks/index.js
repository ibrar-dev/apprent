import React from 'react';
import {connect} from 'react-redux';
import {Input} from 'reactstrap';
import Pagination from '../../../../components/pagination';
import Bank from './bank';
import NewBank from "./newBank";

const headers = [
  {label: '', min: true},
  {label: "Routing Number", sort: 'routing', min: true},
  {label: "Bank Name", sort: 'name'}
];

class Banks extends React.Component {
  state = {filter: ''};

  _filters() {
    const {filter} = this.state;
    const _this = this;
    return <Input value={filter} onChange={({target: {value}}) => _this.setState({filter: value})}/>
  }

  newBank() {
    this.setState({newBank: !this.state.newBank});
  }

  render() {
    const {banks} = this.props;
    const {filter: filterVal, newBank} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return <>
      <Pagination component={Bank}
                  collection={banks.filter(b => filter.test(b.name) || filter.test(b.routing))}
                  title="Banks"
                  headers={headers}
                  filters={this._filters()}
                  field="bank"
                  menu={[
                    {title: 'New Bank', onClick: this.newBank.bind(this)}
                  ]}
                  className="h-100 border-left-0 rounded-0"/>
      {newBank && <NewBank toggle={this.newBank.bind(this)}/>}
    </>;
  }
}

export default connect(({banks}) => {
  return {banks};
})(Banks);