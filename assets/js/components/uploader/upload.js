import axios from 'axios';

const CHUNK_SIZE = 1048576;
const genericFunc = () => {
};

class Upload {
  constructor(file, onStart, onProgress) {
    this.fileReady = new Promise((resolve) => {
      const reader = new FileReader();
      reader.onload = () => {
        this.arrayBuffer = reader.result;
        resolve();
      };
      reader.readAsArrayBuffer(file);
    });
    this.filename = file.name;
    this.fileType = file.type;
    this.onStart = onStart || genericFunc;
    this.onProgress = onProgress || genericFunc;
  }

  upload() {
    return new Promise((resolve) => {
      this.fileReady.then(() => {
        this.doUpload().then(resolve);
      });
    });
  }

  uploadPiece(index, resolve, reject) {
    const slice = this.arrayBuffer.slice(index * CHUNK_SIZE, (index + 1) * CHUNK_SIZE);
    const blob = new Blob([new Uint8Array(slice)], {type: this.fileType});
    const form = new FormData();
    form.append('slice', blob, `${this.uuid}.${index + 1}.${name.split('.').reverse()[0]}`);
    axios.patch('/api/uploads', form).then(() => {
      this.numDone++;
      this.onProgress(this.numDone, this.numPieces);
      if (this.numDone < this.numPieces) {
        this.uploadPiece(index + 1, resolve, reject);
      } else {
        resolve();
      }
    }).catch(() => {
      this.uploadPiece(index, resolve, reject);
    });
  }

  doUpload() {
    this.numPieces = Math.ceil(this.arrayBuffer.byteLength / CHUNK_SIZE);
    this.numDone = 0;

    return new Promise((resolve, reject) => {
      axios.post('/api/uploads', {filename: this.filename, pieces: this.numPieces, type: this.fileType}).then(r => {
        this.onStart(this.numPieces);
        this.uuid = r.data.uuid;
        this.uploadPiece(0, resolve, reject);
      });
    });
  }
}

export default Upload;