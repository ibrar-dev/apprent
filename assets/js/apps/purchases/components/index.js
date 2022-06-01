import React, { useState } from 'react';
import {Card, CardBody, Nav, NavItem, NavLink} from 'reactstrap';
import PurchasesHistory from './purchasesHistory';

const tabs = {
  purchases: PurchasesHistory
};

const Purchases = () => {
  const [activeTab, setActiveTab] = useState('purchases');
  const Component = tabs[activeTab];  
  return (
    <div>
      <Nav tabs>
        <NavItem>
          <NavLink
            active={activeTab === 'purchases'}
            onClick={() => setActiveTab('purchases')}
          >
            <h4 className="m-0">Purchases</h4>
          </NavLink>
        </NavItem>
      </Nav>
      <Card className="border-top-0 rounded-0">
        <CardBody>
          <Component/>
        </CardBody>
      </Card>
    </div>
  )
}

export default Purchases;