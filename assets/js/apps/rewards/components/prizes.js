import React from 'react';
import {connect} from 'react-redux';
import {Input, Button} from 'reactstrap';
import PrizeModal from './prizeModal';
import confirmation from '../../../components/confirmationModal';
import {toCurr} from '../../../utils';
import actions from '../actions';

class Prizes extends React.Component {
  state = {};

  prizeModal(prize) {
    this.setState({prizeModal: !this.state.prizeModal, prize: prize.id ? prize : null});
  }

  changeFilter({target: {value}}) {
    this.setState({filter: value});
  }

  deletePrize(p, e) {
    e.stopPropagation();
    confirmation('Delete this prize?').then(() => {
      actions.deletePrize(p);
    });
  }

  render() {
    const {prizes} = this.props;
    const {prizeModal, filter, prize} = this.state;
    const regex = new RegExp(filter, 'i');
    return <div>
      <div className="d-flex justify-content-between align-items-center">
        <Input value={filter || ''} onChange={this.changeFilter.bind(this)} className="w-50 form-control-lg"
               placeholder="Search"/>
        <Button color="success" onClick={this.prizeModal.bind(this)} outline>
          <i className="fas fa-plus-circle"/> New Prize
        </Button>
      </div>
      <ul className="list-group mt-3">
        {prizes.filter(p => regex.test(p.name)).map(p => {
          return <li key={p.id} onClick={this.prizeModal.bind(this, p)}
                     className={`list-group-item d-flex justify-content-between align-items-center clickable`}>
            <div className="d-flex justify-content-center align-items-center position-relative">
              <div className="d-flex align-items-center justify-content-center rounded-circle overflow-hidden bg-white mr-2"
                   style={{width: 30, height: 30, border: '1px solid rgba(0, 0, 0, 0.2)'}}>
                {p.icon ? <img src={p.icon} className="w-100"/> : <i className="fas fa-question"/>}
              </div>
              <div className="d-flex">
                <div>{p.name}</div>
                <div className="badge badge-pill badge-success ml-1"
                     style={{alignSelf: 'baseline', marginTop: '-3px'}}>
                  {toCurr(p.price)}
                </div>
              </div>
            </div>
            <div className="pr-2">
              {p.points} Points
            </div>
            <a className="position-absolute p-1 close-tab text-danger"
               onClick={this.deletePrize.bind(this, p)}
               style={{fontSize: '80%'}}>
              <i className="fas fa-times"/>
            </a>
          </li>
        })}
      </ul>
      {prizeModal && <PrizeModal toggle={this.prizeModal.bind(this)} prize={prize || {points: 0, promote: true, name: ''}}/>}
    </div>;
  }
}

export default connect(({prizes}) => {
  return {prizes};
})(Prizes);