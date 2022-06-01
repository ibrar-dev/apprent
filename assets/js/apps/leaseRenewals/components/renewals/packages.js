import React from 'react';
import {toCurr} from "../../../../utils";
import Notes from "./notes";
import Package from "./renewalPackage";

class Packages extends React.Component {
  state = {};

  render() {
    const {period, lease, locked} = this.props;
    return <tr>
      <td className="border-0"/>
      <td className="border-0 py-0 nowrap">
        <ul className="pl-3">
          {period.packages.map(p => <li key={p.id} className="d-flex align-items-center justify-content-between">
            <div className="my-1">
              {p.min} - {p.max} months -- {p.base} + {p.dollar ? toCurr(p.amount) : `${p.amount}%`}
            </div>
            <div className="ml-2">
              <Notes notes={p.notes} period={period} data={p} module="package"/>
            </div>
          </li>)}
        </ul>
      </td>
      <td className="border-0 py-0">
        <ul className="pl-0">
          {period.packages.map(p => <li key={p.id} className="d-flex">
            {lease && <Package key={p.id} locked={locked} lease={lease} pkg={p} threshold={period.threshold}/>}
          </li>)}
        </ul>
      </td>
      <td colSpan={2} className="border-0 py-0">
      </td>
    </tr>;
  }
}

export default Packages;