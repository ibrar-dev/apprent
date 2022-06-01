import {Button, Col, Input,Dropdown, DropdownItem, DropdownToggle, DropdownMenu, Row} from "reactstrap";
import React, {Component} from "react";
import Uploader from '../../../components/uploader';
import actions from "../actions";

class CreateDocument extends Component {
    state = {};

    change({target: {name, value}}) {
        this.setState({...this.state, [name]: value});
    }

    changeUpload(file) {
        this.setState({...this.state, file});
    }

    toggle(){
        this.setState({...this.state, dropdownOpen: !this.state.dropdownOpen})
    }

    createDocument(){
        const {file, type} = this.state;
        const {application} = this.props;
        file.upload().then(() => {
            const params = {application_id: application.id , type: type, url: {uuid: file.uuid}};
            actions.createDocument({create_document: true, params: params}).then(() => {
                this.setState({type: null, file: null}, () => actions.fetchApplications().then(r => {
                    if(r.data.applications[0].full === 'true') {
                        actions.fetchUnits();
                        actions.fetchChargeCodes();
                    }
                }))
            })
        });
    }

    render(){
        const {type, file, url} = this.state;
        return <>
            <Row className="pl-2 pr-2 pt-2">
                <Col sm={12} className="mb-3">
                    <div className="d-flex">
                        <div className="labeled-box flex-auto">
                            <Input style={{height: 40}} name="type" type="select" onChange={this.change.bind(this)}>
                                <option>Please Select One</option>
                                <option>Driver's License</option>
                                <option>Pay Stub</option>
                                <option>Other</option>
                            </Input>
                            <div className="labeled-box-label">Type</div>
                        </div>
                    </div>
                </Col>
                <Col sm={12}>
                    <Uploader onChange={this.changeUpload.bind(this)}/>
                </Col>
            </Row>
            <Row>
                <Col sm={12}>
                    <Button className="mt-4 btn-block btn-success" disabled={!type || !file}
                            onClick={this.createDocument.bind(this)}>
                        Upload
                    </Button>
                </Col>
            </Row>
        </>
    }
}

export default CreateDocument;
