import React, {Component} from "react";
import snackbar from "../../../components/snackbar";
import confirmation from "../../../components/confirmationModal";
import actions from "../actions";
import {Button, Col, Input, Modal, ModalBody, ModalHeader, Row} from "reactstrap";
import FancyCheck from "../../../components/fancyCheck";

class NewCategory extends Component {
  state = {name: '', num: '', max: '', total_only: false};

  change({target: {name, value}}) {
    this.setState({[name]: value})
  }

  changeFlag({target: {name, checked}}) {
    this.setState({[name]: checked})
  }

  errorMessage(message) {
    return snackbar({message, args: {type: 'error'}});
  }

  saveCategory() {
    const {name, num, max, total_only} = this.state;
    if (name.length < 1) return this.errorMessage("Category name is required");
    if (num < 10000000 || num > 99999999) return this.errorMessage("Number must be 8 digits");
    confirmation("Please confirm you would like to create this Category").then(() => {
      actions.saveCategory({name, num, max, total_only}).then(this.props.toggle)
    });
  }

  render() {
    const {toggle} = this.props;
    const {name, num, max, total_only} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Add Category
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="d-flex align-items-center">
              <FancyCheck inline label="Total Only" name="total_only" checked={total_only} value={total_only}
                          onChange={this.changeFlag.bind(this)}/>
              <div className="labeled-box ml-2 flex-auto">
                <Input name="name" value={name} onChange={this.change.bind(this)}/>
                <div className="labeled-box-label">Category Name</div>
              </div>
            </div>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col>
            <div className="labeled-box">
              <Input name="num" value={num} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Number</div>
            </div>
          </Col>
          <Col>
            <div className="labeled-box">
              <Input name="max" value={max} onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">Total Account</div>
            </div>
          </Col>
        </Row>
        <Row>
          <Col className="d-flex flex-row-reverse mt-1">
            <Button outline color="success" onClick={this.saveCategory.bind(this)}>Save</Button>
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default NewCategory;