import React from 'react';
import {Badge, CardHeader} from "reactstrap";
import moment from "moment";

class Header extends React.Component {
  state = {};

  leaseBadgeStatus() {
    const {tenant, lease} = this.props;
    const isCurrent = (moment().isBetween(moment(lease.start_date), moment(lease.end_date)) || (!tenant.actual_move_out && !lease.renewal));
    if (lease.start_date < moment()) {
      return 'Future';
    } else if (tenant.eviction_file_date && tenant.actual_move_out) {
      return 'Evicted';
    } else if (tenant.eviction_file_date) {
      return 'Under Eviction';
    } else if (tenant.actual_move_out) {
      return 'Moved Out';
    } else if (isCurrent) {
      return 'Current';
    }  else {
      return 'Month to Month';
    }
  }

  render() {
    const {tenant} = this.props;
    return <CardHeader className="d-flex align-items-center py-2">
      <div>Occupancy <Badge color={tenant.eviction_file_date ? 'danger' : 'primary'}>
        {this.leaseBadgeStatus()}
      </Badge>
      </div>
    </CardHeader>;
  }
}

export default Header;