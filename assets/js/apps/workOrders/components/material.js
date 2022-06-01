import React from 'react';
import {ListGroupItem, ListGroupItemHeading, ListGroupItemText, Button} from 'reactstrap';
import actions from '../actions';
import confirmation from '../../../components/confirmationModal';

class Material extends React.Component {
  state = {};

  inventoryClicked(i) {
    const {m, a, s} = this.props;
    if (["on_hold", "pending", "in_progress"].includes(a.status)) {
      confirmation(`Please confirm that you would like to attach this item: ${m.name} to ${a.tech}, from ${i.stock}`).then(() => {
        const toolbox = {tech_id: a.tech_id, stock_id: i.stock_id, material_id: m.id, assignment_id: a.id};
        actions.attachMaterial(toolbox, a.order_id, s);
      })
    }
  }

  render() {
    const {m} = this.props;
    return <div>
      <ListGroupItem>
        <ListGroupItemHeading className="d-flex justify-content-between">
          <span>{m.name}</span><span>${(m.cost / m.per_unit).toFixed(2)}</span>
        </ListGroupItemHeading>
        <ListGroupItemText>
          {m.inventory.map(i => {
            return (
              <Button
                color="link"
                key={i.stock_id}
                style={{cursor: 'pointer'}}
                onClick={this.inventoryClicked.bind(this, (i))}
              >
                {i.stock}: {i.inventory}
              </Button>
            )
          })}
        </ListGroupItemText>
      </ListGroupItem>
    </div>
  }
};

export default Material;

