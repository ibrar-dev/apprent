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
  state = {divX: {visibility: 'hidden'}};

  addImage({target: {files}}) {
    const reader = new FileReader();
    reader.readAsDataURL(files[0]);
    reader.onload = () => {
      this.setState({imageData: reader.result, divX: DropZoneStyles.xStyles});
    };
    this.props.onChange(files[0]);
  }

  clearImageData(){
    document.getElementById("dropzone_input").value = "";
    this.setState({imageData: null, divX: {visibility: 'hidden'}});
  }

  render() {
    let containerHeight= "";
    let containerStyle= {position: 'relative', height: "100%", width:"100%"};
    let positionOfLabel = "position-relative";
    if(this.state.imageData) {
        containerHeight = "h-100";
        containerStyle= {position: 'relative'};
        positionOfLabel = "position-relative";
    }else {
        containerHeight = "";
        containerStyle = {position: 'relative', height: "100%", width:"100%"};
        positionOfLabel = "position-absolute";
    }
    const x = <div style={this.state.divX} onClick={this.clearImageData.bind(this)}>x</div>
    const {imageData} = this.state;
    const {prompt, style, image} = this.props;
    const src = imageData || image;

    return <div className= {`mb-0 ${containerHeight}`} style={{...containerStyle, ...style}}>
            {x}
            <label
                className={`mb-0 w-100 h-100 d-flex justify-content-center align-items-center ${positionOfLabel} overflow-hidden`}
                style={{cursor: "pointer", border: '2px dashed', top: 0, ...style}}>
                {!src && <span>{prompt || 'Select Image'}</span>}
                {src && <img className="w-100" src={src}/>}
                <input id="dropzone_input" type="file" className="custom-file-input position-absolute"
                       style={{zIndex: -2}}
                       onChange={this.addImage.bind(this)}/>
            </label>
           </div>

  }
}

export default DropZone;