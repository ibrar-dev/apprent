import React from 'react';
import {Input, Button} from 'reactstrap';
import actions from "../actions";
import FloorPlan from "./floorPlan";
import ModeSwitch from './modeSwitch';
import Pagination from '../../../components/pagination';
import PropertySelect from "../../../components/propertySelect";

const headers = [
  {label: "", min: true},
  {label: "Name", sort: 'name'},
  {label: "Features", sort: 'price'},
  {label: "", min: true},
  {label: "Units"},
  {label: "Default Charges"}
];

class FloorPlans extends React.Component {
  state = {filterVal: ''};

  changeFilter(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  _filters() {
    const {filterVal} = this.state;
    return <div className="d-flex">
      <ModeSwitch/>
      <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
    </div>;
  }

  render() {
    const {floorPlans, property, properties, features} = this.props;
    const {filterVal} = this.state;
    const filter = new RegExp(filterVal, 'i');
    const collection = floorPlans.filter(f => filter.test(f.name));
    return <React.Fragment>
      <Pagination
        component={(props) => <FloorPlan {...props} features={features}/>}
        collection={collection}
        title={<div className="d-flex align-items-center">
          <PropertySelect properties={properties} property={property} onChange={actions.setProperty}/>
          {property.id && <Button color="success" size="sm" className="m-0"
                                  onClick={actions.addFloorPlan} style={{width: 110}}>
            New Floor Plan
          </Button>}
        </div>}
        headers={headers}
        filters={this._filters()}
        field="floorPlan"
        headerClassName="p-1"
        className="h-100 border-left-0 rounded-0"
      />
    </React.Fragment>
  }
}

export default FloorPlans;