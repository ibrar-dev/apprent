import React from 'react';
import Feature from './feature';
import {Input, Button} from 'reactstrap';
import ModeSwitch from './modeSwitch';
import Pagination from '../../../components/pagination';
import actions from '../actions';
import PropertySelect from '../../../components/propertySelect';

const headers = [
  {label: "", min: true},
  {label: "Name", sort: 'name'},
  {label: "Price", sort: 'price'},
  {label: "", min: true},
  // {label: "Units"}
];

class Features extends React.Component {
  state = {filterVal: ''};

  changeFilter(e) {
    this.setState({filterVal: e.target.value});
  }

  _filters() {
    const {filterVal} = this.state;
    return <div className="d-flex">
      <ModeSwitch/>
      <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
    </div>;
  }

  render() {
    const {features, property, properties} = this.props;
    const {filterVal} = this.state;
    const filter = new RegExp(filterVal, 'i');
    const collection = features.filter(f => filter.test(f.name));
    return <Pagination
      component={Feature}
      collection={collection}
      title={<div className="d-flex align-items-center">
        <PropertySelect properties={properties} property={property} onChange={actions.setProperty}/>
        {property.id && <Button color="success" size="sm" className="m-0"
                                onClick={actions.addFeature} style={{width: 110}}>
          New Feature
        </Button>}
      </div>}
      headers={headers}
      filters={this._filters()}
      field="feature"
      headerClassName="p-1"
      className="h-100 border-left-0 rounded-0"
    />;
  }
}

export default Features;