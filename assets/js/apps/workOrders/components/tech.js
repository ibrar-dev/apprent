import React from 'react';
import TechIcon from './techIcon';
import actions from '../actions';

class Tech extends React.Component {
  select() {
    this.props.select(this.props.tech.id);
  }

  rescindOffer(e) {
    e.stopPropagation();
    if (confirm('rescind this offer?')) {
      actions.rescindOffer(this.props.offer.id);
    }
  }

  assignWorkOrder(e) {
    e.stopPropagation();
    const {orderId, tech} = this.props;
    actions.assignWorkOrder(tech.id, orderId).then(() => {
      actions.openWorkOrder(orderId, 'workOrder');
    });
  }

  _currentlyAssigned(tech) {
      return tech.assignments.filter(a => {
          return a.status.match('in_progress') || a.status.match('on_hold');
      });
  }

  render() {
    const {tech, selected, offer, callback} = this.props;
    return <li
      key={tech.id}
      className={`list-group-item p-0 ${callback ? 'text-danger' : ''}`}
      style={{backgroundColor: selected ? '#d4edda' : '#fff'}}
    >
      <a onClick={this.select.bind(this, tech.id)} className="d-flex align-items-center p-2">
        <TechIcon
          selected={selected}
          tech={tech}
          color={tech.presence ? 'success' : 'danger'}
        />
        <span>
          {tech.presence && <strong>{tech.name} ONLINE</strong>}
          {!tech.presence && tech.name}
          {callback && ' (callback)'}
        </span>
        <span className="ml-auto">
          {this._currentlyAssigned(tech).length} Current Assignments
        </span>
        <div className="ml-auto">
          {offer && <button className="btn btn-danger btn-sm mr-2" onClick={this.rescindOffer.bind(this)}>
            Offer Sent
          </button>}
          <button className="btn btn-success btn-sm" onClick={this.assignWorkOrder.bind(this)}>
            Assign
          </button>
        </div>
      </a>
    </li>;
  }
}

export default Tech;
