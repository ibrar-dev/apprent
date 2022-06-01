import React from 'react';

const icons = {
  pdf: 'file-pdf',
  jpg: 'file-image',
  png: 'file-image',
  gif: 'file-image',
  tif: 'file-image',
  tiff: 'file-image',
  mp4: 'file-video',
  mov: 'file-video',
  avi: 'file-video',
  mp3: 'file-audio',
  zip: 'file-archive',
  csv: 'file-csv',
  xls: 'file-excel',
  xlsx: 'file-excel',
  doc: 'file-word',
  docx: 'file-word',
};

class Display extends React.Component {
  render() {
    const {filename, ext, loading} = this.props;
    return <div className="display d-flex align-items-center">
      {!loading && <i className={`fas fa-2x fa-${icons[ext]}`}/>}
      {loading && <img src={loading} />}
      <h4 className="mb-0 ml-2">{filename}</h4>
    </div>
  }
}

export default Display;