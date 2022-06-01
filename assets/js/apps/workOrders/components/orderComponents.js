import OpenOrder from './openOrder';
import PendingOrder from './pendingOrder';
import InProgressOrder from './inProgressOrder';
import CompleteOrder from './completeOrder';
import CanceledOrder from './canceledOrder';
import OutsourcedOrder from './outsourcedOrder';

export default {
  open: OpenOrder,
  on_hold: PendingOrder,
  in_progress: InProgressOrder,
  completed: CompleteOrder,
  canceled: CanceledOrder,
  outsourced: OutsourcedOrder
};