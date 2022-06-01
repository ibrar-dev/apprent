import React from 'react';
import {Button, Input} from 'reactstrap';
import {connect} from 'react-redux';
import TypeModal from './typeModal';
import actions from '../actions';
import confirmation from '../../../components/confirmationModal';

class Types extends React.Component {
  state = {};

  typeModal(type) {
    this.setState({typeModal: !this.state.typeModal, type: type.id ? type : null});
  }

  changeFilter({target: {value}}) {
    this.setState({filter: value});
  }

  deleteType(t, e) {
    e.stopPropagation();
    confirmation('Delete this category?').then(() => {
      actions.deleteType(t);
    });
  }

  render() {
    const {types} = this.props;
    const {typeModal, filter, type} = this.state;
    const regex = new RegExp(filter, 'i');
    return <div>
      <div className="d-flex justify-content-between align-items-center">
        <Input value={filter || ''} onChange={this.changeFilter.bind(this)} className="w-50 form-control-lg"
               placeholder="Search"/>
        <Button color="success" onClick={this.typeModal.bind(this)} outline>
          <i className="fas fa-plus-circle"/> New Category
        </Button>
      </div>
      <ul className="list-group mt-3">
        {types.filter(t => regex.test(t.name)).map(t => {
          return <li key={t.id} onClick={this.typeModal.bind(this, t)}
                     className={`list-group-item d-flex justify-content-between align-items-center clickable${t.active ? '' : ' text-muted' }`}>
            <div className="d-flex justify-content-center align-items-center position-relative overflow-hidden">
              <div className="d-flex align-items-center justify-content-center rounded-circle bg-white mr-2"
                   style={{width: 30, height: 30, border: '1px solid rgba(0, 0, 0, 0.2)'}}>
                {t.icon ? <img src={t.icon} className="w-100"/> : <i className="fas fa-question"/>}
              </div>
              <div className="d-flex">
                <div>{t.name}</div>
                <div className="badge">
                  {t.monthly_max} per month
                </div>
              </div>
            </div>
            <div className="pr-2">
              {t.points} Points
            </div>
            <a className="position-absolute p-1 close-tab text-danger"
               onClick={this.deleteType.bind(this, t)}
               style={{fontSize: '80%'}}>
              <i className="fas fa-times"/>
            </a>
          </li>
        })}
      </ul>
      {typeModal && <TypeModal toggle={this.typeModal.bind(this)} type={type || {points: 0, active: true, name: ''}}/>}
    </div>;
  }
}

export default connect(({types}) => {
  return {types};
})(Types);