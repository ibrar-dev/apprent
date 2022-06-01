import React, {Component} from "react";
import actions from "../actions";
import {Button, Col, Input, Row, Modal, ModalBody, ModalHeader} from 'reactstrap';

class MemoModal extends Component {
    constructor(props) {
        super(props);
        this.state = { note: "" };
        this.change = this.change.bind(this);
        this.createMemo = this.createMemo.bind(this);
    }

    change({target: {name, value}}) {
        this.setState({...this.state, [name]: value});
    }

    createMemo(){
        const {note} = this.state;
        const {applicationId, toggle} = this.props;
        const params = {application_id: applicationId, note: note}
        actions.createMemo(params).then(() => {
            this.setState({note: ""}, () => actions.fetchApplications().then(toggle))
        })
    }

    render(){
      const {note} = this.state;
      const {toggle} = this.props;
      return (
        <Modal isOpen toggle={toggle} size="lg">
          <ModalHeader>Create New Memo</ModalHeader>
          <ModalBody>
            <Row className="pl-2 pr-2 pt-2">
              <Col sm={12} className="mb-3">
                <div className="d-flex">
                  <div className="labeled-box flex-auto">
                    <Input
                      type="textarea"
                      name="note"
                      id="note"
                      value={note}
                      onChange={(e) => this.change(e)}
                    />
                    <div className="labeled-box-label">Note</div>
                  </div>
                </div>
              </Col>
            </Row>
            <Row>
              <Col sm={12}>
                <Button
                  className="mt-4 btn-block btn-success"
                  disabled={!note || note.length < 5}
                  onClick={this.createMemo.bind(this)}
                >
                  Create Memo
                </Button>
              </Col>
            </Row>
          </ModalBody>
        </Modal>
      )
    }
}

export default MemoModal;
