import React from "react";
import moment from "moment";
import {Button, Popover, PopoverBody, PopoverHeader} from "reactstrap";

const today = moment().startOf('day');

class Leases {
  constructor(props) {
    this.sortLeases(props);
  }

  sortLeases(props) {
    this.leases = {past: [], current: null, future: [], mtm: null, renewal: null};
    props.unit.leases.forEach(occ => {
      const start = moment(occ.start_date);
      const end = moment(occ.actual_move_out);
      const lease_end = moment(occ.end_date);
      if (!occ.actual_move_out && lease_end.isBefore(today)) return this.leases.mtm = occ;
      if (today.isBefore(start)) return this.leases.future.push(occ);
      if (occ.actual_move_out && end.isBefore(today)) return this.leases.past.push(occ);
      this.leases.current = occ;
    });
    (this.leases.current || this.leases.mtm) && props.unit.leases.forEach(l => {
      if (l.renewal_id === (this.leases.current ? this.leases.current.id : this.leases.mtm.id)) return this.leases.renewal = l;
    })
  }

  dropdown(list, toggle, target, isOpen) {
    return <>
      <Button color="secondary" id={target} onClick={toggle}>
        {list.length} Leases
      </Button>
      <Popover placement="bottom" isOpen={isOpen} target={target} toggle={toggle}>
        <PopoverHeader>Leases</PopoverHeader>
        <PopoverBody>
          <ul className="list-unstyled">
            {list.map(o => {
              return <li key={o.id}>
                <a href={`/tenants/${o.tenants[0].tenancy_id}`}>{o.start_date} to {o.end_date}</a>
              </li>
            })}
          </ul>
        </PopoverBody>
      </Popover>
    </>
  }
}

export default Leases;