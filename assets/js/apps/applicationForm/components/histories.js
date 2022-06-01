import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import History from '../models/history';
import utils from './utils';

class HistoryForm extends React.Component {
  editField(e) {
    actions.editCollection('histories', this.props.index, e.target.name, e.target.value);
  }

  deleteHistory() {
    actions.deleteCollection('histories', this.props.history._id);
  }

  render() {
    const {history, index, lang} = this.props;
    const userField = utils.userField.bind(this, history);
    return <div className="card">
      <div className="card-header">
        {lang.prev_residences}
        {index > 0 && <a className="delete-button" onClick={this.deleteHistory.bind(this)}>
          <i className="fas fa-trash"/>
        </a>}
      </div>
      <div className="card-body pt-0">
        {userField('address', lang.address, 'address')}
        <div className="mt-3">
          {userField('rent', `${lang.rent}?`, 'boolean')}
        </div>
        {history.rent && userField('rental_amount', lang.rental_amount, 'number')}
        {history.rent && userField('landlord_name', lang.landlord_name)}
        {history.rent && userField('landlord_phone', lang.landlord_num, 'phone')}
        {history.rent && userField('landlord_email', lang.landlord_email)}
      </div>
    </div>
  }
}

class Histories extends React.Component {
  render() {
    const {lang, application: {histories}} = this.props;
    return (
      <div>
        {
          histories.map((history, index) => {
            return (
              <HistoryForm
                key={history._id}
                lang={lang}
                index={index}
                history={history}
              />
            )
          })
        }
      </div>
    );
  }
}

export default connect((s) => {
  return {application: s.application, lang: s.language}
})(Histories);
