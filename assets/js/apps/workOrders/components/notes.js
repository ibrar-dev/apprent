import React from 'react';
import {Button, Card, CardBody, CardText, Collapse, Row, Col, Input, CardFooter, CardImg, CardHeader} from 'reactstrap';
import moment from 'moment';
import axios from 'axios';
import {capitalize} from '../../../utils';
import confirmation from '../../../components/confirmationModal';
import canEdit from '../../../components/canEdit';
import actions from '../actions';

const noteSource = (note) => {
  let type = null;
  ['admin', 'tech', 'tenant', 'card'].some(t => {
    if (note[t]) {
      type = t;
      return true;
    }
    return false;
  });
  return capitalize(type);
};

class Notes extends React.Component {
  state = {noteText: '', openNoteId: null, transText: '', transToggle: false};

  togglePopover() {
    this.setState({...this.state, open: !this.state.open});
  }

  changeNoteText(e) {
    this.setState({...this.state, noteText: e.target.value});
  }

  saveNote() {
    const {orderId} = this.props;
    const {image, noteText} = this.state;
    const notes = new FormData();
    notes.append('notes[order_id]', orderId);
    if (image) notes.append('notes[image]', image);
    if (noteText.length >= 2) notes.append('notes[noteText]', noteText);
    actions.saveNote(orderId, notes, this.props.type).then(() => {
      this.setState({...this.state, noteText: '', textOpen: false});
      location.reload();
    });
  }

  openNote(id, e) {
    e.stopPropagation();
    const openNoteId = this.state.openNoteId === id ? null : id;
    this.setState({...this.state, openNoteId});
  }

  translateIndex(index) {
    let requestURL = `https://translation.googleapis.com/language/translate/v2/detect?q=${encodeURI(this.props.notes[index].text)}&&key=AIzaSyApOxMlYpn_cBO57CxFmEnzbU39gPjAOcI`;
    const promise = axios.get(requestURL);
    promise.then(r => {
      const language = r.data.data.detections[0][0].language;
      let transLang = '';
      {
        language === 'en' ? transLang = 'es' : transLang = 'en'
      }
      requestURL = `https://translation.googleapis.com/language/translate/v2?q=${encodeURI(this.props.notes[index].text)}&&target=${transLang}&&key=AIzaSyApOxMlYpn_cBO57CxFmEnzbU39gPjAOcI`;
      const promise = axios.get(requestURL);
      promise.then(r => {
        this.setState({
          ...this.state,
          transText: r.data.data.translations[0].translatedText,
          transToggle: !this.state.transToggle
        });
      })

    });
  }

  translateText(text) {
    let requestURL = `https://translation.googleapis.com/language/translate/v2/detect?q=${encodeURI(text)}&&key=AIzaSyApOxMlYpn_cBO57CxFmEnzbU39gPjAOcI`;
    const promise = axios.get(requestURL);
    promise.then(r => {
      const language = r.data.data.detections[0][0].language;
      let transLang = '';
      language === 'en' ? transLang = 'es' : transLang = 'en';
      requestURL = `https://translation.googleapis.com/language/translate/v2?q=${encodeURI(text)}&&target=${transLang}&&key=AIzaSyApOxMlYpn_cBO57CxFmEnzbU39gPjAOcI`;
      const promise = axios.get(requestURL);
      promise.then(r => {
        this.setState({...this.state, transText: r.data.data.translations[0].translatedText, transToggle: !this.state.transToggle})
      })
    })
  }

  translateToggle(index) {
    {
      !this.state.transToggle ? this.translateIndex(index) : this.setState({
        ...this.state,
        transToggle: !this.state.transToggle
      })
    }
  }

  addImage({target: {files}}) {
    const reader = new FileReader();
    reader.readAsDataURL(files[0]);
    reader.onload = () => {
      this.setState({...this.state, image: files[0], imageData: reader.result});
    };
  }

  clearNote() {
    this.setState({...this.state, imageData: null, noteText: ''});
  }

  deleteNote(id) {
    const {orderId} = this.props;
    confirmation("Please confirm you would like to delete this note. This action cannot be undone").then(() => {
      actions.deleteNote(id, orderId)
    })
  }

  render() {
    const {notes, orderId, assignments, disableAdd, status} = this.props;
    const {open, noteText, openNoteId, transText, transToggle, imageData} = this.state;
    return <React.Fragment>
      {notes.map((note, index) => (
        <div key={note.id}>
          <Button color="outline-info"
                  className="btn-block mb-2"
                  onClick={this.openNote.bind(this, (note.id || 0))}>
            {noteSource(note)} {note.image ? 'Image' : 'Note'}
          </Button>
          <Collapse isOpen={openNoteId === (note.id || 0)}>
            <Card>
              <CardHeader className="d-flex justify-content-between">
                <h6>
                  {note.admin && note.admin}
                  {note.tech && note.tech}
                  {note.tenant && note.tenant}
                  <br/> {moment.utc(note.inserted_at).local().format("YYYY-MM-DD h:mm A")}}
                </h6>
                {canEdit(["Super Admin", "Regional"]) && <span>
                  <i onClick={this.deleteNote.bind(this, note.id)} className={`fas fa-trash cursor-pointer text-danger`} />
                </span>}
              </CardHeader>
              <CardBody style={{paddingTop: "10px"}} className="d-flex flex-column">
                <CardText style={{color: "#7F7C7C"}}>
                  {transToggle ? transText : note.text || note.card}
                  {note.image && <img className="img-thumbnail" src={note.image}/>}
                </CardText>
                {note.text && <Button outline color="secondary" onClick={this.translateToggle.bind(this, index)}> Translate </Button>}
              </CardBody>
            </Card>
          </Collapse>
        </div>
      ))}
      {assignments && assignments.map((a) => {
        return a.tech_comments && <div key={a.id}>
          <Button color="outline-info"
                  className="btn-block mb-2"
                  onClick={this.openNote.bind(this, a.id)}>
            Tech Comment
          </Button>
          <Collapse isOpen={openNoteId === a.id}>
            <Card>
              <h6 style={{paddingLeft: "20px", paddingTop: "5px"}}> {capitalize(a.status)} by {a.tech}
                <br/> {moment.utc(a.updated_at).local().format('MM-DD-YYYY')} </h6>
              <CardBody style={{paddingTop: "10px"}} className="d-flex flex-column">
                {transToggle ? transText : a.tech_comments}
                <Button  outline color="secondary" onClick={this.translateText.bind(this, a.tech_comments)}> Translate </Button>
              </CardBody>
            </Card>
          </Collapse>
        </div>
      })}
      {!disableAdd && status !== "Completed" && <React.Fragment>
        <button className="btn btn-block btn-success mb-3"
                id={`add-note-${orderId}`}
                onClick={this.togglePopover.bind(this, 'textOpen')}>
          Add Text And/Or Image
        </button>
        <div className="row mb-3">
          <div className="col xs-12">
            <Collapse isOpen={open}>
              <Card>
                <Row>
                  <Col md={3}>
                    <label
                      className="mb-0 h-100 d-flex justify-content-center align-items-center"
                      style={{cursor: "pointer", border: '2px dashed'}}>
                      {!imageData && <span>Select Image</span>}
                      {imageData && <CardImg top width="100%" src={imageData}/>}
                      <input type="file" className="custom-file-input position-absolute"
                             onChange={this.addImage.bind(this)}/>
                    </label>
                  </Col>
                  <Col md={9}>
                    <label htmlFor="notes">Notes</label>
                    <Input className="form-control"
                           type="textarea"
                           value={noteText}
                           rows="5"
                           onChange={this.changeNoteText.bind(this)}/>
                  </Col>
                </Row>
                <Collapse isOpen={noteText.length >= 2 || imageData}>
                  <CardFooter className="d-flex justify-content-between">
                    <Button onClick={this.clearNote.bind(this)} outline color="warning">Clear</Button>
                    <Button onClick={this.saveNote.bind(this)} outline color="success">Save</Button>
                  </CardFooter>
                </Collapse>
              </Card>
            </Collapse>
          </div>
        </div>
      </React.Fragment>}
    </React.Fragment>
  }
}

export default Notes;
