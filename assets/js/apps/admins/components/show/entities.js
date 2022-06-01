import React from "react";
import {connect} from "react-redux";
import {Input} from "reactstrap";
import Entity from "../entity";

class Entities extends React.Component {
  constructor(props) {
    super(props);
    this.imgRef = React.createRef();
    this.state = {
      entityFilter: "",
      selectedEntities: [],
    };
  }

  static getDerivedStateFromProps(props, state) {
    const {selectedEntities} = state;
    const {activeAdmin: {entity_ids}} = props;
    if (entity_ids !== selectedEntities) return {selectedEntities: entity_ids};
    return null;
  }

  entityFilter = (e) => {
    this.setState({entityFilter: e.target.value});
  }

  render() {
    const {id} = this.props.activeAdmin;
    const {activeAdmin, entities} = this.props;
    const {entityFilter, selectedEntities} = this.state;
    const entityRegex = new RegExp(entityFilter, "i");
    if (Object.keys(activeAdmin).length === 0) return null;

    return (
      <div style={{padding: 30, paddingLeft: 30, paddingRight: 30}}>
        <div className="d-flex " style={{flexDirection: "column"}}>
          <h4 style={{color: "#97a4af"}}>Entities</h4>
          <Input
              onChange={(e) => this.entityFilter(e)}
              value={entityFilter}
              placeholder="Filter by Name"
            />
          <ul className="list-unstyled admins-entity-list mt-2">
            {
              entities.map((e) => (
                e.name.match(entityRegex)
                  ? (
                    <li key={e.id}>
                      <Entity
                        entity={e}
                        adminId={id}
                        checked={selectedEntities && selectedEntities.includes(e.id)}
                      />
                    </li>
                  )
                  : null
              ))
            }
          </ul>
        </div>
      </div>
    );
  }
}

export default connect(({entities, activeAdmin}) => ({entities, activeAdmin}))(Entities);