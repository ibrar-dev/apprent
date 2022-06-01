import React from 'react';

const DropZoneStyles = {
  xStyles: {
    position: 'absolute',
    right: 1,
    top: 1,
    width: 15,
    height: 18,
    fontSize: 15,
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 100,
    color: 'black',
    background: 'white',
    cursor: 'pointer'
  },
};

class DropZone extends React.Component {
  state = {divX: {display: 'none'}, imageData: this.props.image};

  addImage({target: {files}}) {
    const reader = new FileReader();
    reader.readAsDataURL(files[0]);
    reader.onload = () => {
      this.setState({imageData: reader.result, divX: DropZoneStyles.xStyles});
    };
    this.props.onChange(files[0]);
  }

  clearImageData() {
    document.getElementById("dropzone_input").value = "";
    this.setState({imageData: null, divX: {display: 'none'}});
  }

  render() {
    const {imageData} = this.state;
    const {prompt, style} = this.props;
    const containerStyle = {position: 'relative'};
    if (!imageData) containerStyle.height = 200;
    const labelPosition = imageData ? 'position-relative' : 'position-absolute';
    return <div className="mb-0" style={{...containerStyle, ...style}}>
      <div style={this.state.divX} onClick={this.clearImageData.bind(this)}>x</div>
      <label
        className={`mb-0 w-100 ${imageData ? '' : 'h-100'} d-flex justify-content-center align-items-center ${labelPosition} overflow-hidden`}
        style={{cursor: "pointer", border: '2px dashed', top: 0, ...style}}>
        {!imageData && <span>{prompt || 'Select Image'}</span>}
        {imageData && <img className="w-100" src={imageData}/>}
        <input id="dropzone_input" type="file" className="custom-file-input position-absolute"
               style={{zIndex: -2}}
               onChange={this.addImage.bind(this)}/>
      </label>
    </div>

  }
}

export default DropZone;