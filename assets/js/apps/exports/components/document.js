import React from 'react';
import {ListGroupItem, Button, ButtonGroup, Modal, ModalHeader, ModalBody} from 'reactstrap';
import moment from 'moment';
import confirmation from '../../../components/confirmationModal';
import SendModal from './sendModal';
import actions from '../actions';

class Document extends React.Component {
  state = {};

  deleteDocument() {
    confirmation('Delete this exports?').then(() => {
      actions.deleteExport(this.props.document);
    });
  }

  viewDocument() {
    this.setState({viewMode: !this.state.viewMode});
  }

  sendDocument() {
    this.setState({sendMode: !this.state.sendMode});
  }

  render() {
    const {document} = this.props;
    const {viewMode, sendMode} = this.state;
    return <ListGroupItem className="rounded-0 border-left-0 border-right-0">
      <div className="d-flex justify-content-between">
        <div>
          <ButtonGroup className="mr-3">
            <Button onClick={this.deleteDocument.bind(this)} outline color="info" className="px-1 py-0">
              <i className="fas fa-times"/>
            </Button>
            <Button onClick={this.viewDocument.bind(this)} outline color="info" className="px-1 py-0">
              <i className="fas fa-eye"/>
            </Button>
            <Button onClick={this.sendDocument.bind(this)} outline color="info" className="px-1 py-0">
              <i className="fas fa-share-square"/>
            </Button>
          </ButtonGroup>
          {document.name}
        </div>
        <div>{moment(document.date).format('LLLL')}</div>
      </div>
      <Modal isOpen={viewMode} size="xl">
        <ModalHeader toggle={this.viewDocument.bind(this)}>{document.name}</ModalHeader>
        <ModalBody>
          <iframe src={document.url} className="w-100 border-0" style={{height: '80vh'}}/>
        </ModalBody>
      </Modal>
      {sendMode && <SendModal document={document} toggle={this.sendDocument.bind(this)}/>}
    </ListGroupItem>;
  }
}

export default Document;