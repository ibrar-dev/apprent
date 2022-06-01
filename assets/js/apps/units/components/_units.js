import React from 'react';
import {connect} from 'react-redux';
import Unit from './unit';
import NewUnit from './newUnit';
import {Input} from 'reactstrap';
import Pagination from '../../../components/pagination';
import actions from "../actions";
import PropertySelect from "../../../components/propertySelect";
import UpdatePrices from './updatePrices';

const headers = [
  {label: '', min: true},
  {label: "Number", sort: 'number'},
  {label: "Floor Plan", sort: 'floor_plan'},
  {label: "Market Rent"},
  {label: "Status"},
  {label: "Current Lease"},
  {label: "Upcoming Lease"},
  {label: "Lease History"}
];

class Units extends React.Component {
  state = {filterVal: ''};

  changeFilter(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  _filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
  }

  newUnit() {
    this.setState({newUnit: !this.state.newUnit});
  }

  togglePricesModal() {
    this.setState({...this.state, pricesModal: !this.state.pricesModal});
  }

  render() {
    const {property, properties, units} = this.props;

    if (properties.length == 0) {
      return <div>Loading</div>
    }

    const {filterVal, newUnit, pricesModal} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return <>
      <Pagination component={Unit}
                  collection={units.filter(u => filter.test(u.number))}
                  title={<PropertySelect properties={properties} property={property} onChange={actions.viewProperty}/>}
                  headers={headers}
                  filters={this._filters()}
                  field="unit"
                  tableClasses="sticky-header table-sm"
                  menu={[
                    {title: 'New Unit', onClick: this.newUnit.bind(this)},
                    {title: 'Update prices', onClick: this.togglePricesModal.bind(this)}
                  ]}
                  className="h-100 border-left-0 rounded-0"/>
      {newUnit && <NewUnit toggle={this.newUnit.bind(this)} property={property}/>}
      {pricesModal && <UpdatePrices toggle={this.togglePricesModal.bind(this)} />}
    </>;
  }
}

export default connect(({property, properties, units}) => {
  return {units, properties, property: property || {}}
})(Units)
