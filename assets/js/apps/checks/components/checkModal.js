import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button} from 'reactstrap';
import {numToLang} from '../../../utils';
import printPdf from '../../../utils/pdfPrinter';
import CheckDetails from './checkDetails';
import actions from '../actions';

class CheckModal extends React.Component {

  change({target: {name, value}}) {
    this.setState({...this.state, check: {...this.state.check, [name]: value}});
  }

  print(){
    const {check, toggle} = this.props;
    const params = {id: check.id, amount_lang: numToLang(check.amount).toUpperCase()};
    actions.updateCheck(params).then(() => actions.getShowCheckById(check.id)).then(r => printPdf(r.data)).then(toggle);
  }

  render() {
    const {toggle, check} = this.props;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>
        Check
      </ModalHeader>
      <ModalBody>
        <div id="check-content">
          <CheckDetails check={check}/>
        </div>
      </ModalBody>
      <ModalFooter>
        <Button onClick={this.print.bind(this)} color="success">
          Print
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default CheckModal;