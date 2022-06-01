import React, {Component} from 'react';
import SortableTree from 'react-sortable-tree';
import FileExplorerTheme from 'react-sortable-tree-theme-full-node-drag';
import {Col, Row, Button, Input, UncontrolledPopover, PopoverBody} from 'reactstrap'
import {connect} from 'react-redux';
import actions from '../actions.js'
import confirmation from '../../../components/confirmationModal';

class Permissions extends Component {

  state = {
    treeData: [],
    admin_list: [],
    newAdmins: [],
    searchQuery: ''
  };

  componentDidMount() {
    actions.fetchOrgChart().then(r => this.setLocalData(r));
  }

  setLocalData(r) {
    this.setState({
      treeData: r.data.tree.map(d => this.arranged_data(d)),
      admin_list: r.data.admin_list.map(ad => {
        return {...ad, title: ad.name, subtitle: ad.email}
      }),
      newAdmins: [],
      searchQuery: ""
    })
  }

  arranged_data(data) {
    if (data.length < 2) {
      return data[0]
    } else {
      return {...data[0], title: data[0].name, subtitle: data[0].email, expanded: true, children: data[1].map(d => this.arranged_data(d))}
    }
  }

  removeNode(info) {
    const {node, parentNode} = info;
    if (this.state.newAdmins.length > 0){
      confirmation('Save your work first.')
    }
    else {
      confirmation(`Delete ${node.name}? ${node.children.length > 0 ? (`employees will report to ${parentNode.name} instead.`) : ''}`)
      .then(() => actions.deleteAdmin(node.id))
      .finally(() => {
        console.log("finally")
        actions.fetchOrgChart()
        .then((r) => this.setLocalData(r))
      })
    }
  }

  save(newAdmins){
    actions.save(newAdmins)
    .finally(() => {
      actions.fetchOrgChart()
      .then(r => this.setLocalData(r))
    })
  }

  onChange({name, value}) {
    this.setState({[name]: value})
  }

  update(data){
    let {node, nextParentNode} = data
      this.save({tree: node, parent: nextParentNode})
  }

  generateNodeProps(rowInfo){
    const {currentUser} = this.state;
    if (currentUser && rowInfo.node.path && rowInfo.node.path.includes(currentUser.id)){
      return {
          buttons: [
            <><div className='btn' style={{curser: "pointer"}} id={`menu${rowInfo.node.id}`}>
              <i className="fas fa-ellipsis-v"/>
            </div>
            <UncontrolledPopover placement="bottom" target={`menu${rowInfo.node.id}`}>

              <PopoverBody className="d-flex flex-column pb-0">
                  <Button color='danger' outline onClick={this.removeNode.bind(this, rowInfo)} className="mt-0 btn-spacing">
                    Delete
                  </Button>
              </PopoverBody>
            </UncontrolledPopover>
            </>
          ]
      }
    }
   }

    render(){
      const {newAdmins, searchQuery} = this.state;
      return (
          <div>
            <Row className='m-1'>
              <Col>
                <Input value={searchQuery}
                       onChange={({target: {value}}) => this.setState({searchQuery: value})}
                       placeholder='Search...' />
              </Col>
            </Row>
            <Row className='mt-4'>
            <Col style={{ height: 900}} className='p-3'>
              <SortableTree
                  treeData={this.state.treeData}
                  onChange={(n) => this.onChange({value: n, name: "treeData"})}
                  theme={FileExplorerTheme}
                  getNodeKey={({ node }) => node.admin_id}
                  dndType='this'
                  onMoveNode={this.update.bind(this)}
                  generateNodeProps={this.generateNodeProps.bind(this)}
                />
            </Col>
            <Col md={3} className='p-3'>
              <Row>
                <Input
                  value={this.state.searchQuery}
                  onChange={({target: {value}}) => this.setState({searchQuery: value})}
                  placeholder='Search..'
                  />
            </Row>
                <SortableTree
                  onChange={(n) => this.onChange({value: n, name: "admin_list"})}
                  canDrop={() => false}
                  treeData={this.state.admin_list.filter(ad => ad.name.toLowerCase().includes(this.state.searchQuery))}
                  theme={FileExplorerTheme}
                  dndType='this'
                    />
                </Col>
                </Row>
          </div>
      );
    }
}

export default connect(({admins}) => {
  return {admins};
})(Permissions);
