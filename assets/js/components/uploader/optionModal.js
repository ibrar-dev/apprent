import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Row, Col, Button} from 'reactstrap';
import classset from 'classnames';
import Webcam from 'react-webcam';


class OptionModal extends Component {
  state = {
    webcam: false
  }

  setRef(webcam) {
    this.webcam = webcam;
  }

  toggleWebcam() {
    this.setState({...this.state, webcam: !this.state.webcam});
  }

  captureScreenshot() {
    const {changeScreenshot} = this.props;
    const imageSrc = this.webcam.getScreenshot();
    changeScreenshot(imageSrc)
  }

  render() {
    const {toggle, change, disabled, types, dirty, containerClass} = this.props;
    const {webcam} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader>WebCam or Upload</ModalHeader>
      <ModalBody>
        <Row>
          <Col className="d-flex justify-content-center">
            {!webcam && <i onClick={this.toggleWebcam.bind(this)} className={'fas fa-camera-retro fa-3x cursor-pointer'} />}
            {webcam && <div className={'d-flex flex-column'}>
              <Webcam audio={false}
                      width={400}
                      ref={this.setRef.bind(this)}
                      screenshotFormat="image/jpeg"
                      height={400} />
              <div className="d-flex justify-content-between">
                <Button outline color="warning">
                  <i onClick={this.toggleWebcam.bind(this)} className="fas fa-times-circle" />
                </Button>
                <Button onClick={this.captureScreenshot.bind(this)} outline color="success">
                  <i className="fas fa-save" />
                </Button>
              </div>
            </div>}
          </Col>
        </Row>
        <Row className="mt-2">
          <Col>
            <input type="file" disabled={disabled} accept={types} onChange={change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col className={`${classset({'uploader-container': true, dirty, show: true, [containerClass]: true})} ml-2 mr-2`}>
            <input type="file" disabled={disabled} accept={types} onChange={change.bind(this)}/>
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default OptionModal;