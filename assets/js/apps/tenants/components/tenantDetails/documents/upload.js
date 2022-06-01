import React from 'react';
import {Button, Col, Input, Row} from "reactstrap";
import CheckBox from "../../../../../components/fancyCheck";
import Uploader from "../../../../../components/uploader";
import actions from "../../../actions";

class Upload extends React.Component {
  state = {};

  toggleVisible() {
    this.setState({visible: !this.state.visible});
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  createDocument() {
    const {name, file, visible, type} = this.state;
    file.upload().then(() => {
      const params = {name, visible, type, tenant_id: this.props.tenant.id, document: {uuid: file.uuid}};
      actions.createDocument({document: params}).then(() => {
        this.setState({name: null, file: null, type: null});
      });
    });
  }

  changeUpload(file) {
    this.setState({file});
  }

  render() {
    const {visible, name, file, type} = this.state;
    return <div>
      <h4 className="mb-0 text-info">Upload Document</h4>
      <div className="mt-2">
        <Row>
          <Col sm={8}>
            <div className="d-flex">
              <div className="mr-3 d-flex align-items-center">
                <CheckBox checked={visible} onChange={this.toggleVisible.bind(this)}/> &nbsp;Visible
              </div>
              <div className="labeled-box flex-auto">
                <Input value={name || ''} name="name" onChange={this.change.bind(this)}/>
                <div className="labeled-box-label">Name</div>
              </div>
            </div>
          </Col>
          <Col sm={4}>
            <div className="labeled-box">
              <Input value={type || ''} name="type" onChange={this.change.bind(this)}/>
              <div className="labeled-box-label">File Type</div>
            </div>
          </Col>
        </Row>
        <Row className="mt-3">
          <Col sm={7} className="d-flex align-items-center">
            <Uploader onChange={this.changeUpload.bind(this)}/>
          </Col>
          <Col sm={5}>
            <Button className="btn-block btn-success" disabled={!name || !file || !type}
                    onClick={this.createDocument.bind(this)}>
              Upload
            </Button>
          </Col>
        </Row>
      </div>
    </div>;
  }
}

export default Upload;