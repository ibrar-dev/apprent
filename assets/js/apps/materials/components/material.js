import React from 'react';
import {Button} from 'reactstrap';
import canEdit from '../../../components/canEdit';
import {connect} from 'react-redux';
import actions from '../actions';
import Cell from '../../../components/editableCell';
import Types from './types';
import SendToProperty from './sendToProperty';
import MaterialLogs from './materialLogs';
import DropZone from "../../../components/dropzone";

class Material extends React.Component {
  state = {
    editMaterial: false,
    sendToProperty: false,
    editImage: false
  };

  update(field, value) {
    const {material, stock} = this.props;
    return actions.updateMaterial({id: material.id, [field]: value, stock_id: stock.id});
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
    const material = new FormData();
    material.append('material[image]', image);
    actions.updateImage(this.props.material.id, this.props.stock.id, material, 'materials')
  }

  updateType(e) {
    this.update('type_id', e.target.value);
  }

  sendToProperty() {
    this.setState({...this.state, sendToProperty: !this.state.sendToProperty});
  }

  classToDisplay(material) {
    if (material.inventory < material.desired) return 'danger';
    if (material.inventory === material.desired) return 'warning';
  }

  toggleLogs() {
    this.setState({...this.state, logs: !this.state.logs})
  }

  propertyTable(material) {
    return <React.Fragment>
      <td/>
      <td>{material.image && <img style={{borderRadius: 50}} src={material.image} alt="Material Image" className="img-fluid" />}</td>
      <td>{material.ref_number}</td>
      <td>{material.name}</td>
      <td>{material.cost}</td>
      <td>{material.type}</td>
      <td>{material.inventory}</td>
      <td>{material.per_unit}</td>
      <td/>
    </React.Fragment>
  }

  toggleEditImage() {
    this.setState({...this.state, editImage: !this.state.editImage})
  }

  render() {
    const {material} = this.props;
    const {logs, sendToProperty, image, editImage} = this.state;
    const propertyLoggedIn = canEdit(["Property"]);
    return <tr className={`alert-${this.classToDisplay(material)}`}>
      {propertyLoggedIn && this.propertyTable(material)}
      {!propertyLoggedIn && <React.Fragment>
        <td className="d-flex justify-content-between">
          {material.inventory > 0 && <Button color='success'
            outline
            onClick={this.sendToProperty.bind(this)}>
            <i className="fas fa-truck" />
          </Button>}
          {material.logs >= 1 && <Button onClick={this.toggleLogs.bind(this)} outline color="info" className="ml-1"><i className="fas fa-eye" /></Button>}
        </td>
        <td>
          {(editImage || !material.image) && <DropZone onChange={(file) => this.updateImage(file, "image")} style={{height: 50, borderRadius: 25}} />}
          {material.image && !editImage && <img style={{borderRadius: 50}} onClick={this.toggleEditImage.bind(this)} src={material.image} alt="Material Image" className="img-fluid" />}
          {image && !material.image && <Button outline color="success" onClick={this.saveImage.bind(this)}>Save</Button>}
          {(editImage && material.image) && <Button outline color="warning" onClick={this.toggleEditImage.bind(this)}>Cancel</Button>}
        </td>
        <Cell value={material.ref_number} onSave={this.update.bind(this, 'ref_number')} />
        <Cell value={material.name} onSave={this.update.bind(this, 'name')} />
        <Cell value={material.cost} onSave={this.update.bind(this, 'cost')} type="number" />
        <td>
          <Types selected={material.type_id} onSelect={this.updateType.bind(this)}/>
        </td>
        <Cell value={material.inventory} onSave={this.update.bind(this, 'inventory')} type="number" />
        {/*<td>{material.inventory}</td>*/}
        <Cell value={material.per_unit} onSave={this.update.bind(this, 'per_unit')} type="number" />
        <td className="align-middle nowrap">
          {/*<Button active={materialCart.includes(material)} outline color="info" onClick={this.addToMaterialCart.bind(this, `${materialCart.includes(material) ? 'REMOVE' : 'ADD'}`)}><i className="fas fa-cart-plus" /></Button>*/}
        </td>
      </React.Fragment>}
      {sendToProperty && <SendToProperty material={material} toggle={this.sendToProperty.bind(this)} />}
      {logs && <MaterialLogs toggle={this.toggleLogs.bind(this)} material={material} />}
    </tr>
  }
}



export default connect(({materialCart, stock}) => {
  return {materialCart, stock}
})(Material);
