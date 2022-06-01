import React from 'react';
import { Menu, Dropdown, Button } from 'antd';

const DropDownMenu = ({paymentId, onDeleteBatch, onDeletePayment}) => (
  <Menu>
    <Menu.Item>
      <Button
        type="link"
        onClick={() => window.open(`/payments/${paymentId}`, "_blank")}
      >
        View Payment
      </Button>
    </Menu.Item>
    <Menu.Item>
      <Button
        type="link"
        onClick={onDeleteBatch}
      >
        Delete Batch
      </Button>
    </Menu.Item>
    <Menu.Item>
      <Button
        type="link"
        onClick={onDeletePayment}
      >
        Delete Payment
      </Button>
    </Menu.Item>
  </Menu>
);

const ActionsDropDown = ({paymentId, onDeleteBatch, onDeletePayment}) => (
  <Dropdown
    overlay={(
      <DropDownMenu
        paymentId={paymentId}
        onDeleteBatch={onDeleteBatch}
        onDeletePayment={onDeletePayment}
      />
    )}
    placement="bottomCenter"
    arrow
  >
    <Button type="link">
      Actions
    </Button>
  </Dropdown>
);

export default ActionsDropDown;