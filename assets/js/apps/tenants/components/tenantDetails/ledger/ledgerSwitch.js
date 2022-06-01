import React, {useState} from 'react';
import {ButtonDropdown, DropdownMenu, DropdownToggle, DropdownItem, Button} from "reactstrap";

export default (leases, activeLease, setActiveLease) => {
  const [unitDropdown, setUnitDropdown] = useState(false);
  const switchableLeases = leases.filter(l => !l.renewal);
  return <div className="d-inline-block">
    {switchableLeases && switchableLeases.length > 1 && <ButtonDropdown
      isOpen={unitDropdown}
      toggle={() => setUnitDropdown(!unitDropdown)}
    >
      <DropdownToggle
        color="info"
        className="btn-sm"
        caret>
        {activeLease.closed && <i className="fas fa-lock"/>} Unit {activeLease.unit.number}
      </DropdownToggle>
      <DropdownMenu>
        {switchableLeases.length.map(l => <DropdownItem key={l.id} onClick={() => setActiveLease(l)}>
            Unit {l.unit.number}
          </DropdownItem>
        )}
      </DropdownMenu>
    </ButtonDropdown>}
    {switchableLeases && switchableLeases.length === 1 && <Button size="sm" color="info">
      {activeLease.closed && <i className="fas fa-lock"/>} Unit {activeLease.unit.number}
    </Button>}
  </div>
}