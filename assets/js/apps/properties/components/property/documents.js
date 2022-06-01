import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Button, Input, ListGroupItem, ListGroup, Modal, ModalBody} from 'reactstrap';
import Uploader from '../../../../components/uploader';
import actions from "../../actions";
import PropertySelect from "./propertySelect";

const style = {
  border: '1px solid grey',
  borderRadius: '5px',
  maxHeight: '150px',
  overflowY: 'scroll'
};

class Documents extends React.Component {
  state = {property_ids: [], url: ''};

  componentDidMount() {
    const {property} = this.props;
    actions.fetchPropertyDocuments(property.id).then(() => this.setState({property_ids: [property.id]}));
  }

  componentDidUpdate(prevProps) {
    if (this.props.property.id !== prevProps.property.id) {
      actions.fetchPropertyDocuments(this.props.property.id).then(() => this.setState({
        ...this.state,
        property_ids: [this.props.property.id]
      }));
    }
  }

  addToPropertyIDs(id) {
    let propertyArray = this.state.property_ids;
    propertyArray.includes(id) ? propertyArray.splice(propertyArray.indexOf(id), 1) : propertyArray.push(id);
    this.setState({property_ids: propertyArray});
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  changeUpload(file) {
    this.setState({file});
  }

  createDocument() {
    const {name, file, type, property_ids} = this.state;
    const {property} = this.props;
    file.upload().then(() => {
      const params = {name, type, property_ids, document: {uuid: file.uuid}};
      actions.createAdminDocs({params}).then(() => {
        this.setState({name: null, file: null, type: null}, actions.fetchPropertyDocuments.bind(this, property.id));
      })
    });
  }

  toggleModal() {
    this.setState({modal: !this.state.modal})
  }

  setURL(url) {
    this.setState({modal: true, url: url});
  }

  deleteDocument(id) {
    const {property} = this.props;
    actions.deletePropertyDocs(id).then(() => actions.fetchPropertyDocuments(property.id));
  }

  render() {
    const {documents} = this.props;
    const {modal, name, type, file, url} = this.state;
    return <>
      <Row>
        <Col sm={8}>
          <div className="d-flex">
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
        <Col sm={7}>
          <Uploader onChange={this.changeUpload.bind(this)}/>
          <Button className="mt-4 btn-block btn-success" disabled={!name || !file || !type}
                  onClick={this.createDocument.bind(this)}>
            Upload
          </Button>
        </Col>
        <Col style={style}>
          {this.props.properties.map((p, index) => {
            return (<PropertySelect key={index} property={p} checked={this.addToPropertyIDs.bind(this)}
                                    property_ids={this.state.property_ids}/>)
          })}
        </Col>
      </Row>
      <ListGroup className={"mt-2"}>
        {documents.map(d => {
          return <ListGroupItem className="p-0 d-flex" key={d.id}>
            <a onClick={this.deleteDocument.bind(this, d.document_id)} className="btn text-left">
              <i className="fas fa-times text-danger"/>
            </a>
            <a onClick={this.setURL.bind(this, d.url)}
               className="btn d-block w-100 text-left pl-0 d-flex justify-content-between">
              <div>{d.name}</div>
              <div>{d.type}</div>
            </a>
          </ListGroupItem>
        })}
      </ListGroup>
      <Modal size="lg" isOpen={modal} toggle={this.toggleModal.bind(this)}>
        <ModalBody style={{height: '80vh', justifyContent: 'center', alignItems: 'center'}}>
          <iframe src={url}
                  style={{display: 'block', overflow: "hidden", height: '100%', width: '100%'}} height="100%"
                  width="100%"/>
        </ModalBody>
      </Modal>
    </>
  }
}

export default connect(({documents, property, properties}) => {
  return {documents, property, properties};
})(Documents);