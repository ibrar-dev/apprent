import React, {Component} from 'react';
import {Dropdown, DropdownToggle, DropdownMenu, DropdownItem, Input} from 'reactstrap';
import actions from '../../actions';

const Note = ({note, last}) => {
  return <DropdownItem disabled toggle={false} style={{marginBottom: last ? 70 : ''}}
                       className={`d-flex flex-column rounded-pill mt-1 ${last ? 'border-bottom border-success' : ''} lastMessage`}>
    <span className="text-muted">{note.admin}</span>
    <span>{note.text}</span>
  </DropdownItem>
};

class Notes extends Component {
  state = {note: '', open: false};

  toggleOpen() {
    this.setState({...this.state, open: !this.state.open})
  }

  updateNote({target: {value}}) {
    this.setState({...this.state, note: value})
  }

  saveNote() {
    const {data, module, period} = this.props;
    const {note} = this.state;
    if (!note) return;
    actions.addNote({id: data.id, note: note, module: module}, period.id).then(() => this.setState({note: ''}));
  }

  handleKeyPress(e) {
    if (e.key === 'Enter') {
      return this.saveNote();
    }
  }

  render() {
    const {notes, large} = this.props;
    const {note, open} = this.state;
    return <Dropdown direction="left" isOpen={open} toggle={this.toggleOpen.bind(this)}>
      <DropdownToggle tag="span" style={{cursor: 'pointer'}} onClick={this.toggleOpen.bind(this)}>
        <div className="position-relative">
          <i className={`fas ${large ? 'fa-2x' : (notes.length > 0 ? 'text-danger' : '')} fa-comments`}/>
          {large && <span className="badge badge-pill badge-danger position-absolute d-flex align-items-center"
                style={{top: -2, right: -4, width: 18, height: 18}}>
            {notes.length}
          </span>}
        </div>
      </DropdownToggle>
      <DropdownMenu className="bg-transparent border-info"
                    style={{width: 350, minHeight: 75, maxHeight: 450, overflowY: 'scroll'}}>
        <div className="bg-light" style={{maxHeight: 350, overflowY: 'scroll'}}>
          {notes.length && notes.map((n, i) => {
            return <Note note={n} key={i} last={notes[i] === notes[notes.length - 1]}/>
          })}
        </div>
        <DropdownItem divider/>
        <DropdownItem toggle={false} className="d-flex bg-info"
                      style={{bottom: 0, maxHeight: 100, overflowY: 'scroll', position: 'fixed'}}>
          <Input className="flex-fill" type="textarea" value={note} placeholder="Add Comment"
                 onChange={this.updateNote.bind(this)} onKeyPress={this.handleKeyPress.bind(this)}/>
          <i className="fas fa-plus-square fa-2x ml-1" onClick={this.saveNote.bind(this)}/>
        </DropdownItem>
      </DropdownMenu>
    </Dropdown>
  }
}

export default Notes;