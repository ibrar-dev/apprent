import React from 'react';
import {ListGroup, ListGroupItem} from "reactstrap";
import moment from "moment";
import confirmation from "../../../../../components/confirmationModal";
import actions from "../../../actions";

class View extends React.Component {
  state = {};

  deleteDocument(id) {
    confirmation('Delete this document?').then(actions.deleteDocument.bind(null, id));
  }

  toggleDocVisible(document) {
    actions.updateDocument({...document, visible: !document.visible});
  }

  render() {
    const {tenant} = this.props;
    return <div>
      <h4 className="mb-0 text-info">View Documents</h4>
      <ListGroup style={{marginTop: 15}}>
        {tenant.documents.map(doc => {
          return <ListGroupItem key={doc.id} className="p-0 d-flex">
            <a onClick={this.deleteDocument.bind(this, doc.id)} style={{width: 35}}
               className="btn-block btn text-left">
              <i className="fas fa-times text-danger"/>
            </a>
            <a onClick={this.toggleDocVisible.bind(this, doc)} style={{width: 25}}
               className="btn-block btn text-left mt-0 pl-0">
              <i className={`fas fa-eye${doc.visible ? '' : '-slash'} text-info`}/>
            </a>
            <a href={doc.url} target="_blank" style={{boxShadow: 'none'}}
               className="btn d-block w-100 text-left pl-0 d-flex justify-content-between">
              <div>{doc.name} - {moment(doc.inserted_at).format('MM/DD/YYYY')}</div>
              <div>{doc.type}</div>
            </a>
          </ListGroupItem>
        })}
      </ListGroup>
    </div>;
  }
}

export default View;