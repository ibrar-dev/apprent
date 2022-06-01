import React from "react";
import {connect} from "react-redux";
import {Input, Button} from "reactstrap";
import AdminRow from "./adminRow";
import NewAdmin from "./newAdmin";
import Pagination from "../../../components/pagination";

const headers = [
  {label: 'Name/Username/Email', sort: 'name'},
  {label: 'Roles', sort: null},
  {label: 'Email Addresses'},
  {label: 'Entities'}
];

class AdminsApp extends React.Component {
  state = {filterVal: ''};

  toggleNewAdmin() {
    this.setState({newAdmin: !this.state.newAdmin});
  }

  changeFilter(e) {
    this.setState({filterVal: e.target.value});
  }

  _filters() {
    const {filterVal} = this.state;
    return <Input value={filterVal} onChange={this.changeFilter.bind(this)}/>
  }

  filtered() {
    const {filterVal} = this.state;
    const {admins} = this.props;
    const regex = new RegExp(filterVal, 'i');
    return admins.filter(a => {
      return a.email.match(regex) || a.name.match(regex) || a.username.match(regex);
    });
  }

  render() {
    const {newAdmin} = this.state;
    return (
      <>
        <Pagination
          title={
          <div>
            <Button color="info" className="m-0" onClick={this.toggleNewAdmin.bind(this)}>
              Add New
            </Button>
            <Button color="info" className="ml-1" href="/admin_actions">
              Admin Actions
            </Button>
          </div>
          }
          type="row"
          tableClasses="m-0"
          collection={this.filtered()}
          component={AdminRow}
          headers={headers}
          filters={this._filters()}
          field="admin"
        />
        {newAdmin && <NewAdmin toggle={this.toggleNewAdmin.bind(this)}/>}
      </>
    )
  }
}

export default connect((state) => ({admins: state.admins, activeAdmin: state.activeAdmin}))(AdminsApp);
