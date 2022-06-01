import React from "react";
import {connect} from "react-redux";
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, ButtonGroup, Input, Row, Col} from "reactstrap";
import {DatePicker} from "antd";
import confirmation from "../../../components/confirmationModal";
import Select from "../../../components/select";
import actions from "../actions";
import moment from "moment";

class CardItemDetail extends React.Component {
  state = {item: {...this.props.item, completed: !!this.props.item.completed}, mode: "tech"};

  change({target: {name, value}}) {
    this.setState({item: {...this.state.item, [name]: value}});
  }

  changeDate(value) {
    this.setState({item: {...this.state.item, scheduled: value}});
  }

  changeMode(mode) {
    this.setState({mode, item: {...this.state.item, tech_id: null, vendor_id: null}});
  }

  save() {
    const {toggle} = this.props;
    const {item} = this.state;
    delete item.completed;
    const func = item.id ? "updateCardItem" : "createCardItem";
    actions[func](item).then(toggle);
  }

  markComplete() {
    confirmation("Mark this item complete?").then(() => {
      const {item} = this.state;
      delete item.completed;
      actions.updateCardItem(item, "complete").then(this.props.toggle);
    });
  }

  revertComplete() {
    confirmation("Revert this item as incomplete?").then(() => {
      const {item} = this.state;
      delete item.completed;
      actions.updateCardItem(item, "revert").then(this.props.toggle);
    });
  }

  render() {
    const {toggle, techs, vendors, name, item: {status}} = this.props;
    const {item, mode} = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader className="d-flex align-items-center justify-content-between" toggle={toggle}>
        <div className="font-weight-bold" style={{fontSize: "135%", textTransform: "uppercase"}}>{name}</div>
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="mb-3">Scheduled</div>

            <DatePicker
              value={item.scheduled && moment(item.scheduled)}
              onChange={(val) => this.changeDate(val)}
              disabled={mode === "vendor"}
              dateFormat="YYYY-MM-DD"
              style={{width: "100%", borderRadius: "3px"}}
            />
          </Col>
          <Col>
            <div className="mb-2">
              <ButtonGroup>
                <Button size="sm" color="info" outline={mode !== "tech"} onClick={this.changeMode.bind(this, "tech")}>
                  Tech
                </Button>
                <Button size="sm" color="info" outline={mode !== "vendor"}
                        onClick={this.changeMode.bind(this, "vendor")}>
                  Vendor
                </Button>
              </ButtonGroup>
            </div>
            {mode === "tech" && <Select onChange={change} name="tech_id" value={item.tech_id}
                                        options={techs.map(t => ({label: t.name, value: t.id}))}/>}
            {mode === "vendor" && <Select onChange={change} name="vendor_id" value={item.vendor_id}
                                          options={vendors.map(t => ({label: t.name, value: t.id}))}/>}
          </Col>
        </Row>
        <Row>
          <Col>
            <div className="my-2">Notes:</div>
            <Input type="textarea" value={item.notes || ""} name="notes" onChange={change}/>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter className="d-flex justify-content-between">
        {
          status !== "Admin Completed"
          && (
            <Button color="danger" onClick={this.markComplete.bind(this)}>
              Mark Complete
            </Button>
          )
        }
        {
          status === "Admin Completed"
          && (
            <Button onClick={this.revertComplete.bind(this)}>
              Revert Complete
            </Button>
          )
        }
        <Button color="success" onClick={this.save.bind(this)}>
          Save
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({techs, vendors, vendor_categories}) => {
  return {techs, vendors, vendor_categories};
})(CardItemDetail);
