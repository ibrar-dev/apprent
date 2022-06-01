import React from 'react';
import {connect} from 'react-redux';
import classset from 'classnames';
import {extract} from '../config';
import actions from '../actions';
import {Input, Card} from "reactstrap";
import {toCurr} from "../../../utils";

class Sidebar extends React.Component {
  switchStage(stage) {
    actions.setStage(stage);
  }

  changeLang(e) {
    actions.setLanguage(e.target.value);
  }

  render() {
    const {stage, application, lang, property} = this.props;
    if(!application || Object.keys(application).length === 0) return null;
    const labels = extract('label');
    const keys = Object.keys(application)
    keys.slice(0, keys.length - 1).forEach(s => application[s].validate())
    return <Card className="mb-2">
      <div className="card-header">Application</div>
      <ul className="list-unstyled m-0">
        <li className="listItemSidebar p-2 d-flex">
          <Input type="select" value={lang.language === "Espanol" ? "es_419" : "en_us"}
                 onChange={this.changeLang.bind(this)}>
            <option value="en_us">English</option>
            <option value="es_419">Espanol</option>
          </Input>
        </li>
        {Object.keys(labels).map((stg, index) => {
          if (!labels[stg]) return null;
          const formPart = application[stg];
          let error = (formPart.hasErrors && formPart.hasErrors()) || (stg === 'employments' && application.income && application.income.hasErrors());
          
          return <li onClick={this.switchStage.bind(this, stg)}
                     style={{fontSize: "12px", paddingLeft: "18px", paddingRight: "18px"}}
                     className={classset({active: stage === stg, listItemSidebar: true, done: formPart.done, error})}
                     key={index}>
            <div className="flex-row d-flex justify-content-between">
              {lang[stg]}
              {stage === stg && <i className="fas fa-chevron-right align-self-center"/>}
              {stage !== stg && !error && formPart.done && <i className="fas fa-check text-success align-self-center"/>}
              {stage !== stg && error && <i className="fas fa-times text-danger align-self-center"/>}
            </div>
          </li>
        })}
      </ul>
    </Card>
  }
}

export default connect((state) => {
  return {stage: state.stage, application: state.application, lang: state.language, property: state.property};
})(Sidebar);
