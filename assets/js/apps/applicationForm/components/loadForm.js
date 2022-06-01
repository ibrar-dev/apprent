import React from 'react';
import {connect} from 'react-redux';
import {Button, Modal, ModalHeader, ModalBody, ModalFooter, Input} from 'reactstrap';
import actions from '../actions';

class LoadForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  loadModal() {
    this.setState({...this.state, modalOpen: true});
  }

  toggleModal() {
    this.setState({...this.state, modalOpen: !this.state.modalOpen});
  }

  load() {
    const {email, pin} = this.state;
    const data = {property_id: this.props.property.id, email, pin};
    actions.loadForm(data).then(() => {
      this.setState({...this.state, loadError: null});
      this.toggleModal();
    }).catch((e) => {
      if (e.response.status === 403) {
        this.setState({...this.state, loadError: e.response.data.error});
      } else if (e.response.status === 500) {
        this.setState({
          ...this.state,
          loadError: 'Oops!  Something seems to have gone wrong on our server, please contact support'
        });
      }
    });
  }

  setCreds(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  render() {
    const {email, pin, loadError} = this.state;
    const {lang} = this.props;
    return <React.Fragment>
      <div className='d-flex flex-column'>
        <Button outline color="success" onClick={this.loadModal.bind(this)}>
          {lang.continue_saved}
        </Button>
      </div>
      <Modal isOpen={this.state.modalOpen} toggle={this.toggleModal.bind(this)}>
        <ModalHeader toggle={this.toggleModal.bind(this)}>
          {lang.continue_saved}
        </ModalHeader>
        <ModalBody>
          <p>Enter your Email and PIN number to continue your saved application.</p>
          <div className="row">
            <div className="col-md-6">
              <input className="form-control"
                     name="email"
                     value={email || ''}
                     placeholder="Email"
                     onChange={this.setCreds.bind(this)}/>
            </div>
            <div className="col-md-6">
              <input className="form-control"
                     name="pin"
                     type="password"
                     value={pin || ''}
                     placeholder="PIN"
                     autoComplete="new-password"
                     onChange={this.setCreds.bind(this)}/>
            </div>
          </div>
          {loadError && <div className="row">
            <div className="col-md-12">
              <em className="invalid-feedback d-block">{loadError}</em>
            </div>
          </div>}
        </ModalBody>
        <ModalFooter>
          <Button color="primary" onClick={this.toggleModal.bind(this)}>Cancel</Button>{' '}
          <Button color="success" onClick={this.load.bind(this)} disabled={!email || !pin}>Load</Button>
        </ModalFooter>
      </Modal>
    </React.Fragment>;
  }
}

export default connect((s) => {
  return {property: s.property, lang: s.language};
})(LoadForm);