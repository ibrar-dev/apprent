import React from 'react';
import {connect} from 'react-redux';
import {withRouter} from 'react-router';
import {Button, Popover, PopoverHeader, PopoverBody} from 'reactstrap';
import actions from '../actions';
import Cell from '../../../components/editableCell';
import ImportModal from './importModal';
import DropZone from "../../../components/dropzone";

class Material extends React.Component {
  state = {};

  updateStock(field, value) {
    const {stock} = this.props;
    return actions.updateStock({id: stock.id, [field]: value});
  }

  updateImage(file, name) {
    this.setState({...this.state, [name]: file})
  }

  addImage({target: {files}}) {
    const reader = new FileReader();
    reader.readAsDataURL(files[0]);
    reader.onload = () => {
      this.setState({...this.state, image: files[0], imageData: reader.result});
    };
  }

  saveImage() {
    const {image} = this.state;
    const stock = new FormData();
    stock.append('stock[image]', image);
    actions.updateImage(this.props.stock.id, this.props.stock.id, stock, 'stocks')
  }

  toggleEditImage() {
    this.setState({...this.state, editImage: !this.state.editImage})
  }

  removeProp(propertyId) {
    if (confirm("Remove this property from this stock?")) {
      const {stock} = this.props;
      const propertyIds = stock.properties.reduce((acc, p) => p.id === propertyId ? acc : acc.concat([p.id]), []);
      return actions.updateStock({id: stock.id, property_ids: propertyIds});
    }
  }

  toggleProps() {
    this.setState({...this.state, propsOpen: !this.state.propsOpen});
  }

  addProp(e) {
    if (confirm("Attach this property to this stock?")) {
      const {stock} = this.props;
      const propertyIds = stock.properties.map(p => p.id);
      propertyIds.push(e.target.value);
      actions.updateStock({id: stock.id, property_ids: propertyIds}).then(() => {
        this.toggleProps();
      });
    }
  }

  importModal() {
    this.setState({...this.state, importModal: !this.state.importModal})
  }

  render() {
    const {stock, properties, history} = this.props;
    const {importModal, image, editImage} = this.state;
    properties.sort((a, b) => a.name < b.name ? -1 : 1);
    return <tr>
      <td>
        <Button color="outline-info" onClick={() => history.push(`/materials/${stock.id}`)}>
          View
        </Button>
      </td>
      <td>
        {(editImage || !stock.image) && <DropZone onChange={(file) => this.updateImage(file, "image")} style={{height: 50, borderRadius: 25}} />}
        {stock.image && !editImage && <img style={{borderRadius: 50}} onClick={this.toggleEditImage.bind(this)} src={stock.image} alt="Stock Image" className="img-fluid" />}
        {image && !stock.image && <Button outline color="success" onClick={this.saveImage.bind(this)}>Save</Button>}
        {(editImage && stock.image) && <Button outline color="warning" onClick={this.toggleEditImage.bind(this)}>Cancel</Button>}
      </td>
      <Cell value={stock.name} onSave={this.updateStock.bind(this, 'name')}/>
      <td>
        <ul className="list-unstyled mb-0">
          {stock.properties.map(p => <li key={p.id}>
            {stock.properties.length > 1 && <a onClick={this.removeProp.bind(this, p.id)}>
              <i className="fas fa-times text-danger"/>
            </a>}
            {' '}
            {p.name}
          </li>)}
        </ul>
        <Button id={`add-prop-${stock.id}`} color="success" onClick={this.toggleProps.bind(this)}>
          <i className="fas fa-plus"/> Attach Property
        </Button>
        <Popover placement="top" isOpen={this.state.propsOpen} target={`add-prop-${stock.id}`}
                 toggle={this.toggleProps.bind(this)}>
          <PopoverHeader>Choose Property to Attach</PopoverHeader>
          <PopoverBody>
            <select className="form-control" onChange={this.addProp.bind(this)}>
              <option/>
              {properties.map(p => {
                return p.stock_id ? null : <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              })}
            </select>
          </PopoverBody>
        </Popover>
      </td>
      <td className="text-right">
        <span className="mr-3">{stock.materials && stock.materials > 1 ? `${stock.materials} materials` : `${stock.materials} material`}</span>
        <div className="btn-group">
          {/*<Button color="outline-info" onClick={actions.fetchMaterialLogs.bind(null, stock.id, moment().subtract(7, 'days').format("YYYY-MM-DD"), moment().format("YYYY-MM-DD"))}>*/}
          <Button color="outline-info" onClick={() => history.push(`/materials/${stock.id}/report`)}>
            View Report
          </Button>
          <Button color="outline-info" onClick={this.importModal.bind(this, stock.id)}>
            Import CSV
          </Button>
          <Button color="outline-info" onClick={() => this.props.printStock(stock.id)}>
            Print Barcodes
          </Button>
        </div>
      </td>
      {importModal && <ImportModal stockId={stock.id} toggle={this.importModal.bind(this)}/>}
    </tr>
  }
}

export default withRouter(connect(({properties}) => {
  return {properties};
})(Material));