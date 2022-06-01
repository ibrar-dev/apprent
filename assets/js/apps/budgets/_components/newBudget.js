import React, {Component} from 'react';
import {connect} from "react-redux";
import moment from 'moment';
import {Row, Col, Button, ListGroup, ListGroupItem, Modal} from 'reactstrap';
import canEdit from '../../../components/canEdit';
import Uploader from '../../../components/uploader';
import Pagination from '../../../components/simplePagination';
import confirmation from '../../../components/confirmationModal';
import {titleize} from "../../../utils";
import actions from '../actions';

class Error extends Component {
  render() {
    const {error} = this.props;
    return <tr>
      <td>{moment.utc(error.date).local().format("MM/DD/YY hh:mm a")}</td>
      <td>{error.log}</td>
    </tr>
  }
}

class ErrorsModal extends Component {
  headers = {
    columns: [
      {label: 'Date', min: true},
      {label: 'Error', sort: 'name'}
    ], style: {color: '#7d7d7d'}
  };

  render() {
    const {errors, toggle} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <Pagination
        title={`Import Error Log (${errors.length})`}
        collection={errors}
        component={Error}
        headers={this.headers}
        field="error"
        hover={true}
      />
    </Modal>
  }
}

class NewBudget extends Component {
  state = {document: null};

  constructor(props) {
    super(props);
    actions.fetchImports();
  }

  changeAttachment(att) {
    if (!att.filename) return;
    att.upload().then(() => {
      this.setState({...this.state, document: {uuid: att.uuid}})
    })
  }

  saveTemplate() {
    const {document} = this.state;
    const {property} = this.props;
    const budget_import = {
      document: document,
      status: "not_started",
      property_id: property.id,
      admin_id: window.admin_id
    };
    actions.uploadBudget(budget_import)
  }

  downloadCSV(url) {
    setTimeout(() => {
      const response = {
        file: url
      };
      window.location.href = response.file;
    }, 100)
  }

  setErrors(errors) {
    this.setState({...this.state, errors: errors})
  }

  beginImport(id) {
    confirmation('Please confirm you would like to begin the import of this budget. Please note any unlocked lines will be overwritten by whatever is in this CSV.').then(() => {
      actions.beginImport(id)
    })
  }

  render() {
    const {property, imports} = this.props;
    const {errors} = this.state;
    return <Row className="mt-1">
      <Col xs={7}>
        <ListGroup>
          {!imports.length && <ListGroupItem>No Previous Imports Available</ListGroupItem>}
          {imports && imports.length > 0 && imports.map(i => {
            return <ListGroupItem key={i.id} className="d-flex justify-content-between">
              <div className="d-flex flex-column flex-fill">
                <span>{i.admin}</span>
                <div className="d-flex justify-content-between">
                  <span>{moment.utc(i.inserted_at).local().format("MM/DD/YY hh:mm a")}</span>
                  <span>Status: {titleize(i.status)}</span>
                  <span onClick={this.setErrors.bind(this, i.errors)}>Errors:
                    <span className={`badge badge-pill badge-${i.errors.length ? 'danger' : 'success'}`}>{i.errors.length}</span>
                  </span>
                  <div className="right-buttons">
                    <i className="fas fa-download cursor-pointer" onClick={this.downloadCSV.bind(this, i.csv)} />
                    {i.status !== "completed" && !i.is_loading && <i onClick={this.beginImport.bind(this, i.id)} className="ml-2 fas fa-play-circle cursor-pointer" />}
                  </div>
                </div>
              </div>
            </ListGroupItem>
          })}
          {errors && <ErrorsModal errors={errors} toggle={this.setErrors.bind(this, null)} />}
        </ListGroup>
      </Col>
      <Col xs={5}>
        <Button block outline color="info" onClick={() => actions.downloadTemplate(property.id)}>Download Template</Button>
        <Button block outline color="info" onClick={() => actions.fetchImports()}>Refresh Status</Button>
        <div className="mt-1">
          <Uploader className="mt-1" onChange={this.changeAttachment.bind(this)}/>
          <Button onClick={this.saveTemplate.bind(this)} className="mt-1" disabled={!canEdit(["Super Admin", "Accountant"])} block outline color="success">Upload Budget</Button>
        </div>
      </Col>
    </Row>
  }
}

export default connect(({property, imports}) => {
  return {property, imports}
})(NewBudget)