import React from "react";
import {connect} from "react-redux";
import {Input, Button, Card, CardHeader, CardBody, CardTitle, CardText,Table }  from "reactstrap";
import Vendor from "./vendor";
import NewVendor from './newVendor';
import Pagination from '../../../../components/pagination'
import actions from "../../actions";

const headers = [
  {label: 'Name', sort: 'name'},
  {label: 'Contact', min: true},
  {label: 'Categories'},
  {label: 'Properties'},
  {label: '', min: true}
];

class VendorsApp extends React.Component {
  state = {filterVal: ''};

  toggleNewVendor(){
    this.setState({...this.state, newVendor: !this.state.newVendor});
  }

  changeFilter(e){
    this.setState({...this.state, filterVal: e.target.value});
  }

  _filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
  }

  filtered() {
    const {filterVal} = this.state;
    const {vendors} = this.props;
    const regex = new RegExp(filterVal, 'i');
    return vendors.filter(v => {
      return (v.email && v.email.match(regex)) || (v.name && v.name.match(regex)) || (v.address && v.address.match(regex)) || (v.phone && v.phone.match(regex)) || (v.categories && v.categories.match(regex));
    });
  }

  pageToggle() {
    this.setState({...this.state, vendorPage: !this.state.vendorPage});
  }

  render() {
    const {newVendor} = this.state;
    const {vendors} = this.props;
    return (
      <React.Fragment>
        {vendors && <React.Fragment>
          <Button color="info" className="mb-3" onClick={this.toggleNewVendor.bind(this)}>
            Add New
          </Button>
          <Pagination
            title="Vendors"
            collection={this.filtered()}
            headers={headers}
            component={Vendor}
            filters={this._filters()}
            field="vendor"
            additionalProps={{changeVendor: this.props.changeVendor}}
            hover={true}
          />
        </React.Fragment>
        }
        {newVendor && <NewVendor toggle={this.toggleNewVendor.bind(this)}/>}
      </React.Fragment>
    )
  }
}

export default connect(({vendors}) => {
  return {vendors}
})(VendorsApp)
