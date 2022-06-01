import React from 'react';

class Scanner extends React.Component {
  constructor(props) {
    super(props);
    this.ref = React.createRef();
    this.state = {scanning: props.autoStart};
    if (props.autoStart) this.startScan();
  }

  startScan() {
    navigator.mediaDevices.getUserMedia({audio: false, video: true}).then(stream => {
      this.setState({imgSrc: null, scanning: true, stream});
      this.ref.current.srcObject = stream;
    }).catch(err => alert("An error occurred: " + err));
  }

  takePic() {
    const video = this.ref.current;
    const canvas = document.createElement('canvas');
    canvas.width = video.offsetWidth;
    canvas.height = video.offsetHeight;
    const context = canvas.getContext('2d');
    context.drawImage(video, 0, 0, video.offsetWidth, video.offsetHeight);
    this.props.onScan(canvas.toDataURL('image/png'));
    this.state.stream.getTracks()[0].stop();
    this.setState({stream: null, scanning: false, imgSrc: canvas.toDataURL('image/png')});
  }

  render() {
    const {imgSrc, scanning} = this.state;
    if (imgSrc) return <img className="img-fluid" src={imgSrc}/>;
    return <div>
      {scanning && <video style={{width: '100%'}} playsInline autoPlay ref={this.ref}/>}
      {scanning && <button className="btn btn-success" onClick={this.takePic.bind(this)}>Take Picture</button>}
      {!scanning && <button className="btn btn-success" onClick={this.startScan.bind(this)}>Start Scan</button>}
    </div>;
  }
}

export default Scanner;