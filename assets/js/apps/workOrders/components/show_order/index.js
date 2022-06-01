import React from 'react';

import MaintenanceOrder from './maintenance_order';
import Order from '../../components/order';

function showOrder({type}) {
  switch (type) {
    case 'vendor':
      return <Order type={'vendor'} />;
      break;
    default:
      return <MaintenanceOrder />;
  }
}

export default showOrder;
