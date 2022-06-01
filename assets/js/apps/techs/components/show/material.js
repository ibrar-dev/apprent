import React from 'react';
import {ListGroupItem, ListGroupItemText, ListGroupItemHeading, Button} from 'reactstrap';
import actions from '../../actions';
import confirmation from '../../../../components/confirmationModal';


class Material extends React.Component {
  state = {}

  sendToTech(i) {
    const {m} = this.props;
    confirmation(`Please confirm that you have handed ${m.name} to ${this.props.tech.name} \nThis item will become available to the tech immediately`).then(() => {
      const toolbox_item = {material_id: m.id, stock_id: i.stock_id, tech_id: this.props.tech.id};
      actions.sendToTech(toolbox_item, this.props.search);
    })
  }

  render() {
    const {m} = this.props;
    return <ListGroupItem>
      <ListGroupItemHeading className="d-flex justify-content-between">
        <span>{m.name}</span><span>${(m.cost / m.per_unit).toFixed(2)}</span>
      </ListGroupItemHeading>
      <ListGroupItemText>
        {m.inventory.map(i => {
          return <Button onClick={this.sendToTech.bind(this, i)} key={i.id} className="m-1" outline color="success">
            {i.stock}: {i.inventory}
          </Button>
        })}
      </ListGroupItemText>
    </ListGroupItem>
  }
}

export default Material;

// export default DragSource(
//   ItemTypes.MATERIAL, materialSource, collect
// )(Material);