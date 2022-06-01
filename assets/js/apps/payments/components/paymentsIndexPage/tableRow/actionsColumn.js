import React from 'react';
import {Button} from 'antd';
import ActionsDropDown from './actionsDropDown';

const ActionsColumn = ({
  isAbleToDelete,
  paymentId,
  onDeleteBatch,
  onDeletePayment,
}) => (
  isAbleToDelete
    ? (
      <ActionsDropDown
        paymentId={paymentId}
        onDeleteBatch={onDeleteBatch}
        onDeletePayment={onDeletePayment}
      />
    )
    : (
      <Button
        type="link"
        onClick={() => window.open(`/payments/${paymentId}`, "_blank")}
      >
        View Payment
      </Button>
    )
);

export default ActionsColumn;
