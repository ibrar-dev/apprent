import React from "react";
import {connect} from "react-redux";
import {Input, Button, Label, Modal, ModalHeader, ModalBody, ModalFooter, Row, Col, Card} from "reactstrap";
import actions from "../actions";
import icons from '../../../components/flatIcons';

class Vendor extends React.Component {
  state = {
    ...this.props.vendor,
    edit: false,
    invalidAttributes: false,
    newCat: '',
    vendorModal: false,
    order: null
  };

  componentWillReceiveProps(props) {
    this.setState({...props.vendor});
  }

  updateVendor() {
    const {name, phone, email, category_ids, newCat} = this.state;
    if (name === '' || phone === '' || email === '' || category_ids === []) {
      this.setState({invalidAttributes: true});
    } else {
      if (newCat) this.state.category_ids.push(newCat);
      actions.updateVendor(this.state);
    }
  }

  toggleEdit(e) {
      e.stopPropagation();
    if (this.state.edit) this.updateVendor();
    this.setState({...this.state, edit: !this.state.edit, newCat: null});
  }

  change({target}) {
    this.setState({...this.state, [target.name]: target.value});
  }

  deleteVendor(e) {
      e.stopPropagation();
    if (confirm("Delete this Vendor?")) {
      actions.deleteVendor(this.props.vendor)
    }
  }

  deleteCategory(cat) {
    if (confirm("Delete this Category?")) {
      actions.deleteCategory(cat)
    }
  }

  changeCategoryIds({target: {value}}) {
    const {category_ids} = this.state;
    const id = parseInt(value);
    category_ids.includes(id) ? category_ids.splice(category_ids.indexOf(id), 1) : category_ids.push(id);
    this.setState({category_ids: category_ids});
  }

  changeNewCat({target: {value}}) {
    this.setState({newCat: value});
  }

  toggleNewCat() {
    const {newCat} = this.state;
    this.setState({newCat: newCat ? null : 'New Category'});
  }

  toggleVendorModal(){
      this.setState({...this.state, vendorPage: !this.state.vendorPage});
  }
    addToPropertyIDs(id) {
        var propertyArray = this.state.property_ids;
        propertyArray.includes(id) ? propertyArray.splice(propertyArray.indexOf(id), 1) : propertyArray.push(id);
        this.setState({property_ids: propertyArray});
    }

  render() {
    const {name, email, address, phone, category_ids,property_ids,contact_name, edit, newCat} = this.state;
      const style = {
          border: '1px solid grey',
          borderRadius: '5px',
          maxHeight: '150px',
          overflowY: 'scroll'
      };

    return <tr onClick = {!edit ? actions.showVendor.bind(null,this.state) : null}>
          <td style = {{width:"350px"}}>
              <p className="m-0">
                  {edit ? <Input name="name" value={name} onChange={this.change.bind(this)}/> : name}
              </p>
          </td>
          <td>
              <ul className="list-unstyled">
                  <li>
                      <b>Email: </b>
                      {edit ? <Input name="email" value={email} onChange={this.change.bind(this)}/> : email}
                  </li>
                  <li>
                      <b>Address: </b>
                      {edit ? <Input name="address" value={address} onChange={this.change.bind(this)}/> : address}
                  </li>
                  <li>
                      <b>Phone: </b>
                      {edit ? <Input name="phone" value={phone} onChange={this.change.bind(this)}/> : phone}
                  </li>
                  <li>
                      <b>Contact Name: </b>
                      {edit ? <Input name="phone" value={phone} onChange={this.change.bind(this)}/> : contact_name || "N/A"}
                  </li>
              </ul>
          </td>
          <td style = {{width:"300px"}}>
              <Card style= {{ overflowY: "auto", paddingLeft: edit ? "20px":"0px", borderWidth: "0px" }}>
              <ul className="list-unstyled">
                  {this.props.categories.map(p => (edit || category_ids.includes(p.id)) && <li key={p.id}>
                              {edit && <Input type="checkbox"
                                              value={p.id}
                                              checked={category_ids.includes(p.id)}
                                              onChange={this.changeCategoryIds.bind(this)}
                                              />}
                              {p.name}
                          {edit && <a onClick={this.deleteCategory.bind(this, p)} style={{float: "right"}}>
                              <i className="fas fa-times text-danger"/>
                          </a>}

                  </li>)}
              </ul>
                  <div>
                  {edit && <img height= "23" src={!newCat ? icons.plus : icons.error} style= {{ float: "left", width: "20px"}} onClick={this.toggleNewCat.bind(this)}>
                  </img>}
                  {edit && newCat && <Input value={newCat} onChange={this.changeNewCat.bind(this)} style={{width: "200px", marginLeft: "10px", float: "left"}}/>}
                  </div>
              </Card>
          </td>
          <td style = {{width:"250px"}}>
              <Card style= {{maxHeight: "260px", overflowY: "auto", paddingLeft: edit ? "20px":"0px", borderWidth: edit ? "1px" : "0px" }}>
              <ul className="list-unstyled" style= {{marginLeft: "0px"}}>
                  {this.props.properties.map(p => (edit || property_ids.includes(p.id)) && <li key={p.id} >
                      {edit && <Input type="checkbox"
                                 value={p.id}
                                 checked={property_ids.includes(p.id) ? 'true' : ''}
                                 onChange={this.addToPropertyIDs.bind(this,p.id)}/>}
                      {p.name}
                  </li>)}

              </ul>
              </Card>
          </td>
          <td>
              <div className="d-flex">
                  <Button outline color="info"
                          className="mr-3"
                          onClick={this.toggleEdit.bind(this)}>
                      {edit ? 'Save' : 'Edit'}
                  </Button>
                  <Button outline color="danger" className="mr-3" onClick={edit ? this.toggleEdit.bind(this) : this.deleteVendor.bind(this)}>{edit ? 'Cancel' : 'Delete'}</Button>
              </div>
          </td>
      </tr>;

  }
}


export default connect(vendors => {
  return (vendors);
})(Vendor);