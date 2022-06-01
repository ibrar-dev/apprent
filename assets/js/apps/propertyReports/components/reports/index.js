import React from 'react';
import {connect} from 'react-redux';
// import Availability from './availabilityReport';
import Delinquency from './delinquencyReport';
import MTM from './mtmReport';
import RentRoll from './rentRoll';
import MoveOuts from './moveOuts';
import Collection from './collectionReport';
import DailyDeposit from './dailyDeposit';
import AgingReport from './agingReport';
import GrossPotentialRent from './grossPotentialRent';
import AdminActions from './adminActions';
import NewBoxScore from './residentActivity';
import ExpiringLeases from './expiringLeasesReport';
import ResidentDirectory from './residentDirectory';
import BoxScore from './boxScore';

class Report extends React.Component {
  render() {
    const {report} = this.props;
    switch (report) {
      // case 'availability':
      //   return <Availability/>;
      case 'boxscore':
        return <BoxScore />;
        // return <NewBoxScore />;
      case 'delinquency':
        return <Delinquency/>;
      case 'mtm':
        return <MTM/>;
      case 'rent_roll':
        return <RentRoll/>;
      case 'collection':
        return <Collection/>;
      case 'move_outs':
        return <MoveOuts/>;
      case 'daily_deposit':
        return <DailyDeposit/>;
      case 'aging':
        return <AgingReport/>;
      case 'admin_actions':
        return <AdminActions/>;
      case 'gpr':
        return <GrossPotentialRent/>;
      case 'expiring_leases':
        return <ExpiringLeases/>;
      case 'resident_directory':
        return <ResidentDirectory />
      default:
        return <div/>
    }
  }
}

export default connect(({report}) => {
  return {report}
})(Report)
