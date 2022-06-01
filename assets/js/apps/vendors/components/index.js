import React from "react";
import {connect} from "react-redux";
import {Input, Button, Card, CardHeader, CardBody, CardTitle, CardText,Table }  from "reactstrap";
import Vendor from "./vendor";
import NewVendor from './newVendor';
import Pagination from '../../../components/pagination'
import actions from "../actions";

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
    const {orders} = this.props;
    return (
      <React.Fragment>

          {orders === null ? <React.Fragment>
              <Pagination
          title={<div>
            Vendors
            <Button color="success" className="ml-4" onClick={this.toggleNewVendor.bind(this)}>
              Add New
            </Button>
          </div>}
          collection={this.filtered()}
          headers={headers}
          component={Vendor}
          filters={this._filters()}
          field="vendor"
          hover={true}/>
          </React.Fragment> :
              <Card>
                  <CardHeader tag="h3">Vendor {orders.vendor.name}
                  <Button onClick={actions.showVendor.bind(null,null)} style = {{float : 'right'}}> back </Button>
                  </CardHeader>
                  <CardBody>
                      <CardTitle>{orders.vendor.name}</CardTitle>
                      <CardText>Address : {orders.vendor.address}</CardText>
                      <CardText>Email : {orders.vendor.email}</CardText>
                      <CardText>Phone : {orders.vendor.phone}</CardText>
                     <Table>
                       <thead>
                      <tr>
                          <th>Property</th>
                          <th>Unit</th>
                          <th>Tenant</th>
                          <th>Category</th>
                          <th>Status</th>
                          <th>Ticket</th>
                      </tr>
                       </thead>
                         <tbody>
                         {orders.orders.map(order => {
                             return <React.Fragment key={order.id} ><tr >
                                 <td>{order.property}</td>
                                 <td>{order.unit}</td>
                                 <td>{order.tenant}</td>
                                 <td>{order.category}</td>
                                 <td>{order.status}</td>
                                 <td>{order.ticket}</td>
                             </tr>
                             </React.Fragment>
                         })}
                         </tbody>
                     </Table>
                      <Button onClick={actions.showVendor.bind(null,null)}> back </Button>
                  </CardBody>

              </Card>
          }
          {newVendor && <NewVendor toggle={this.toggleNewVendor.bind(this)}/>}
      </React.Fragment>)
  }
}

export default connect(vendors => {
  return (vendors)
})(VendorsApp)