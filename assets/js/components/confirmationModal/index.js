import React from 'react';
import {Modal, ModalFooter, ModalHeader, ModalBody, Button} from 'reactstrap';
import ReactDom from 'react-dom';

const deferred = {};

class Store {
  setState(state) {
    this.modal.changeState(state);
  }

  subscribe(modal) {
    this.modal = modal;
  }
}

const store = new Store();

function confirm(message, config = {}) {
  store.setState({isOpen: true, config: {...config, message}});
  const promise = new Promise((resolve) => deferred.resolve = resolve);
  const promiseFill = {
    then(f) {
      promise.then((r) => {if (r) f()});
      return promiseFill;
    },
    catch(f) {
      promise.then((r) => {if (!r) f()});
      return promiseFill;
    },
    finally(f) {
      promise.finally(f);
      return promiseFill;
    }
  };
  return promiseFill;
}

class ConfirmationModal extends React.Component {
  constructor(props) {
    super(props);
    store.subscribe(this);
    this.state = {config: {}};
  }

  respond(answer) {
    deferred.resolve(answer);
    delete deferred.resolve;
    this.setState({config: {}, isOpen: false});
  }

  changeState(newState){
    this.setState(newState);
  }

  render() {
    const {isOpen, config} = this.state;
    return <Modal isOpen={isOpen}>
      <ModalHeader>
        {config.header || 'Confirm'}
      </ModalHeader>
      <ModalBody>
        {config.message}
      </ModalBody>
      <ModalFooter>
        {!config.noCancel && <Button onClick={this.respond.bind(this, false)} color="danger">
          {config.cancelBtn || 'Cancel'}
        </Button>}
        <Button onClick={this.respond.bind(this, true)} color="success">
          {config.okBtn || 'OK'}
        </Button>
      </ModalFooter>
    </Modal>
  }
}

ReactDom.render(<ConfirmationModal/>, document.getElementById('app-modal'));

export default confirm;
