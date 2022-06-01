import React from 'react';
import {Modal, ModalBody, Progress, Button} from 'reactstrap';
import classset from 'classnames';
import Upload from './upload';
import Display from './display';
import Dummy from './dummy';
import OptionModal from './optionModal';
import moment from 'moment';

const filename = (url) => {
  if (url) {
    const path = ((u) => {
      try {
        return (new URL(url)).pathname;
      } catch (_) {
        return u;
      }
    })(url);
    const loading = url.match(/^\/images\/((loading)|(error))\.svg\?/) ? url : null;
    const filename = decodeURI(path.split('/').reverse()[0]);
    const ext = filename.split('.').reverse()[0];
    return {filename, ext, loading};
  }
};

class Uploader extends React.Component {
  state = {...filename(this.props.url), options: false};

  componentDidMount() {
    const {oldFile, onChange} = this.props;
    oldFile ? onChange(oldFile) : onChange(new Dummy());
  }

  changeFile({target: {files}}) {
    const fileInfo = files.length === 1 ? filename(files[0].name) : Array.from(files).map(file => filename(file.name))
    const {clearUpload, onChange, multiple} = this.props;
    const uploads = [];
    multiple ? this.setState({fileInfo, dirty: true, options: false}) : this.setState({...fileInfo, dirty: true, options: false});
    Array.from(files).forEach(file => {
      if (clearUpload) clearUpload.clear().then(this.clear.bind(this));
      uploads.push(new Upload(file, this.startUpload.bind(this), this.onProgress.bind(this)))
    })
    multiple ? onChange(uploads) : onChange(uploads[0]);
  }

  changeFileScreenshot(data) {
    let arr = data.split(','), mime = arr[0].match(/:(.*?);/)[1],
      bstr = atob(arr[1]), n = bstr.length, u8arr = new Uint8Array(n);
    while (n--) {
      u8arr[n] = bstr.charCodeAt(n)
    }
    let file = new File([u8arr], `AppRent_ScreenShot_${moment().format("YYYY_MM-DD_h_mm_ss")}`, {type: mime});
    this.changeFile({target: {files: [file]}})
  }

  startUpload(numPieces) {
    this.setState({numPieces, uploading: true});
  }

  clear() {
    this.setState({uploading: false, dirty: false, filename: null, ext: null, loading: null});
  }

  onProgress(numDone) {
    this.setState({numDone});
    if (this.state.numPieces === numDone) {
      setTimeout(() => {
        this.setState({uploading: false, dirty: false});
      }, 500);
    }
  }

  toggleOption() {
    this.setState({options: !this.state.options})
  }

  render() {
    const {uploading, numPieces, numDone, filename, ext, dirty, loading, options} = this.state;
    const {disabled, hidden, containerClass, label, types, modal, showName, placeholder, multiple} = this.props;
    return <div className={classset({'uploader-container': true, dirty, show: !hidden, [containerClass]: true})}>
      {placeholder && <div className="w-100 h-100 d-flex justify-content-center">
        <strong>{placeholder}</strong>
      </div>}
      {options &&
      <OptionModal changeScreenshot={this.changeFileScreenshot.bind(this)} toggle={this.toggleOption.bind(this)}
                   disabled={disabled} containerClass={containerClass} types={types} dirty={dirty}
                   change={this.changeFile.bind(this)}/>}
      {filename && !hidden && <Display filename={filename} ext={ext} loading={loading}/>}
      {((!filename && !hidden) || showName) && label}
      {modal && <Button style={{display: 'none'}} onClick={this.toggleOption.bind(this)}/>}
      {!modal && <input type="file" disabled={disabled} accept={types} onChange={this.changeFile.bind(this)} multiple={multiple}/>}
      {uploading && <Modal isOpen={true}>
        <ModalBody>
          <h4 className="text-center">Uploading Attachments</h4>
          <div className="upload-progress">
            <Progress color="success" max={numPieces} value={numDone}/>
          </div>
          <div className="text-center">
            Uploaded {numDone} / {numPieces}MB
          </div>
        </ModalBody>
      </Modal>}
    </div>
  }
}

export default Uploader;