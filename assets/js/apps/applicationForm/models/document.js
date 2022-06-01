import Model from './model';
import Dummy from '../../../components/uploader/dummy';

class Document extends Model {

  data() {
    return this.type;
  }

  fileData() {
    return this._data.file;
  }

}

Document.fields = [
  {
    field: 'type',
    defaultValue: '',
    validation: (type) => type.length > 1 ? true : 'document_type_error'
  },
  {
    field: 'file',
    defaultValue: (new Dummy()),
    validation: (file) => (
      file instanceof Dummy ? 'document_type_error' : true
    )
  },
];

export default Document;
