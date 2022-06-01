import React from 'react';
import {connect} from 'react-redux';
import Pagination from '../../../components/pagination';
import PropertySelect from '../../../components/propertySelect';
import Select from '../../../components/select';
import Closing from "./closing";
import NewMonth from './newMonth';
import actions from '../actions';

const headers = [
  {label: '', min: true},
  {label: 'Month'},
  {label: 'Closed on'},
  {label: 'Closed by'}
];

const typeOptions = [
  {value: 'payables', label: 'Payables'},
  {value: 'journal_entries', label: 'Journal Entries'}
];

class ClosingsApp extends React.Component {
  state = {type: 'payables'};

  toggleNewMonth() {
    this.setState({newMonth: !this.state.newMonth});
  }

  changeType({target: {value}}) {
    this.setState({type: value});
  }

  render() {
    const {newMonth, type} = this.state;
    const {properties, closings, property} = this.props;

    if (properties.length == 0) {
      return (
        <p>Loading</p>
      )
    }

    const propertySelect = <PropertySelect properties={properties} property={property}
                                           onChange={actions.selectProperty}/>;
    if (!property) return propertySelect;
    const months = closings.filter(p => p.property_id === property.id && p.type === type);
    return <>
      <Pagination collection={months}
                  component={Closing}
                  headers={headers}
                  field="closing"
                  headerClassName="p-1"
                  filters={<div style={{minWidth: 180}}>
                    <Select value={type} options={typeOptions} onChange={this.changeType.bind(this)}/>
                  </div>}
                  menu={[{title: 'New Closing', onClick: this.toggleNewMonth.bind(this)}]}
                  title={propertySelect}/>
      {newMonth && <NewMonth property={property} months={months} toggle={this.toggleNewMonth.bind(this)}/>}
    </>;
  }
}

export default connect(({properties, closings, property}) => {
  return {properties, closings, property};
})(ClosingsApp);
