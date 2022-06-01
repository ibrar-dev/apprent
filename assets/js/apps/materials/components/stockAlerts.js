import React, { Component } from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Nav, NavItem, NavLink, Badge, Button} from 'reactstrap';
import {connect} from "react-redux";
import Pagination from '../../../components/pagination';
import {PDFCon} from "./pdfconverter";
import FileExport from "../../workOrders/components/fileExport";

class MaterialComponent extends Component {
  render() {
    const {material: material} = this.props;
    return <tr>
      <td>{material.name}</td>
      <td>{material.inventory}</td>
      <td>{material.desired}</td>
      <td>${material.cost}</td>
      <td>{(material.desired - material.inventory) > 0 ? (material.desired - material.inventory) : null}</td>
      <td>{(material.desired - material.inventory) > 0 ? `$${Math.round(((material.desired - material.inventory) * material.cost) * 100) / 100}` : null}</td>
    </tr>
  }
}

class StockAlerts extends Component {
  state = {
    activeTab: 'negative',
  };
  headers = [
    {label: "Name", sort: 'name'},
    {label: "Current Inventory", sort: 'inventory'},
    {label: "Minimum Desired", sort: 'desired'},
    {label: "Item Cost", sort: 'cost'},
    {label: "Amount Needed", sort: null},
    {label: "Total Cost", sort: null}
  ];

  componentWillMount() {
    const {materials} = this.props;
    const sorted = {negative: [], below: [], low: []};
    materials.forEach(m => {
      if (m.inventory < 0) return sorted.negative.push(m);
      if (m.inventory < m.desired) return sorted.below.push(m);
      if ((m.desired - m.inventory) <= 2) return sorted.low.push(m);
      return m;
    });
    this.setState({...this.state, sorted: sorted});
  }

  toggleExport() {
    this.setState({...this.state, modal: !this.state.modal});
  }

  changeTab(type) {
    this.setState({...this.state, activeTab: type});
  }

  filterChange(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  buildPDF_CSV() {
    const {activeTab, sorted, filterVal} = this.state;
    const materials = sorted[activeTab];
    const files = PDFCon(materials, filterVal);
    this.setState({...this.state, pdf: files.pdf, csv: files.csv, modal: true});
  }

  render() {
    const {stock, toggle} = this.props;
    const {activeTab, sorted, filterVal, pdf, csv, modal} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return <Modal isOpen={true} toggle={toggle} style={{maxWidth: '75%'}}>
      <ModalHeader>
        <span>Alerts for <b>{stock.name}</b></span>
      </ModalHeader>
      <ModalBody>
        <div className="d-flex justify-content-between">
          <Nav pills>
            <NavItem>
              <NavLink active={activeTab === 'negative'} onClick={this.changeTab.bind(this, 'negative')}>
                <i className="fas fa-minus-circle" />{' '}Negative <Badge color="danger" pill>{sorted.negative.length}</Badge>
              </NavLink>
            </NavItem>
            <NavItem>
              <NavLink active={activeTab === 'below'} onClick={this.changeTab.bind(this, 'below')}>
                <i className="fas fa-less-than" />{' '}Order Report <Badge color="danger" pill>{sorted.below.length}</Badge>
              </NavLink>
            </NavItem>
            <NavItem>
              <NavLink active={activeTab === 'low'} onClick={this.changeTab.bind(this, 'low')}>
                <i className="fas fa-shopping-cart" />{' '}Running Low <Badge color="danger" pill>{sorted.low.length}</Badge>
              </NavLink>
            </NavItem>
          </Nav>
          <Button outline color="info" onClick={this.buildPDF_CSV.bind(this)}>Export</Button>
        </div>
        <div className="mt-1 mb-1">
          {activeTab === "negative" && <div>
            <Pagination title="Materials with Negative Inventory"
                        component={MaterialComponent}
                        headers={this.headers}
                        filters={<input className="form-control" value={filterVal || ''} onChange={this.filterChange.bind(this)}/>}
                        field="material"
                        collection={sorted.negative.filter(m => filter.test(m.ref_number) || filter.test(m.name))}>
            </Pagination>
          </div>}
          {activeTab === "below" && <div>
            <Pagination title="Materials with an Inventory below the desired amount"
                        component={MaterialComponent}
                        headers={this.headers}
                        filters={<input className="form-control" value={filterVal || ''} onChange={this.filterChange.bind(this)}/>}
                        field="material"
                        collection={sorted.below.filter(m => filter.test(m.ref_number) || filter.test(m.name))}>
            </Pagination>
          </div>}
          {activeTab === "low" && <div>
            <Pagination title="Materials with an inventory close to the minimum desired amount"
                        component={MaterialComponent}
                        headers={this.headers}
                        filters={<input className="form-control" value={filterVal || ''} onChange={this.filterChange.bind(this)}/>}
                        field="material"
                        collection={sorted.low.filter(m => filter.test(m.ref_number) || filter.test(m.name))}>
            </Pagination>
          </div>}
        </div>
        {pdf && <FileExport modal={modal} toggle={this.toggleExport.bind(this)} pdf={pdf} csv={csv}/>}
      </ModalBody>
      <ModalFooter>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({stock, materials}) => {
  return {stock, materials}
})(StockAlerts);