import moment from 'moment';

export default (tenant) => {

    if (moment(tenant.start_date) > moment()) {
      return 'Future';
    } else if (tenant.eviction && tenant.actual_move_out) {
      return 'Evicted';
    } else if (tenant.eviction) {
      return 'Under Eviction';
    } else if (tenant.actual_move_out) {
      return 'Moved Out';
    } else if (tenant.renewal) {
      return 'Renewal'
    // } else if (isCurrent) {
    //   return 'Month To Month';
    } else {
      return 'Current Lease';
    }
  }