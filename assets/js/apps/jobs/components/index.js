import React from "react";
import {connect} from "react-redux";
import TabbedBox from "../../../components/tabbedBox";
import Job from './job';

class Jobs extends React.Component {
  state = {};

  setTab(tab) {
    this.setState({activeId: tab.id})
  }

  render() {
    const {jobs, jobTypes} = this.props;
    const links = Object.keys(jobTypes).sort((w1, w2) => jobTypes[w1] > jobTypes[w2] ? 1 : -1).map(worker => {
      const desc = jobTypes[worker];
      const currentJobs = jobs.filter(j => j.function === worker);
      const label = <div className="d-flex align-items-center justify-content-between">
        {desc}
        <span className={`badge badge-${currentJobs.length > 0 ? 'success' : 'danger'}`}>
          {currentJobs.length}
        </span>
      </div>;
      return {id: worker, label, data: {jobs: currentJobs, desc}, icon: false};
    });
    const {activeId} = this.state;
    const active = links.find(l => l.id === activeId) || {};
    return <TabbedBox links={links}
                      active={active.id}
                      onNavigate={this.setTab.bind(this)}>
      {active.id && <Job worker={active}/>}
    </TabbedBox>;
  }
}

export default connect(({jobs, jobTypes}) => {
  return {jobs, jobTypes}
})(Jobs);