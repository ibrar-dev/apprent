import React, {Component} from 'react';
import {Table, Collapse, Modal} from 'reactstrap';
import {toCurr} from '../../../../utils';
import moment from 'moment';
import jsPDF from 'jspdf';

const sortByType = (arr, type) => {
    const types = {};
    arr.forEach(u => {
        if(types[u[type]]){
            types[u[type]].push(u);
        }else{
            types[u[type]] = [u];
        }
    });
    return Object.entries(types);
};

class BoxScore extends Component{

    state={modal: false}

    findType(){
        const {unitStatus} = this.props;
        return sortByType(unitStatus, 'status');
    }

    declareType(title){
        switch (title) {
            case "Occupied":
                return {type: "occ", status: "Occupied", fields: ['current_rent', 'actual_move_in', 'start_date', 'end_date'], headers: [{label: "Current Rent", sort: "current_rent"}, {label: "Move In", sort: "actual_move_in"}, {label: "Lease Start", sort: "start_date"} , {label: "Lease End", sort: "end_date"}]};
            case "Notice Unrented":
                return {type: "nnr", status: "Notice Unrented", fields: ['current_rent', 'notice_date'], headers: [{label: "Current Rent", sort: "current_rent"}, {label: "Notice Date", sort: "notice_date"}]};
            case "Notice Rented":
                return {type: "nr", status:  "Notice Rented", fields: ['current_rent', 'notice_date'], headers: [{label: "Current Rent", sort: "current_rent"}, {label: "Notice Date", sort: "notice_date"}]};
            default:
                return {type: "", status: "", field: [], headers: []};
        }
    }

    toggleModal(sE){
        const {modal} = this.state;
        if(!modal && sE){
            this.setState({modal: true, sortedEntries: sE});
        }else{
            this.setState({modal: false, sortedEntries: null});
        }
    }

    buildOverview(type){
        return sortByType(this.props.unitStatus, 'floor_plan').map(([floorPlan, entries], i) => {
            const {marketRent, sortedEntries} = entries.reduce( (acc, e) => {
                if(e.status === type){
                    acc.sortedEntries.push(e);
                    acc.marketRent += parseFloat(e.market_rent);
                }
                return acc;
            }, {marketRent: 0, sortedEntries: []});
            return <tr key={`${this.props.title} ${floorPlan} ${i}`}>
                <td>{floorPlan}</td>
                <td><a onClick={sortedEntries && sortedEntries.length && this.toggleModal.bind(this, sortedEntries)}>{sortedEntries.length}</a></td>
                <td>{toCurr(marketRent)}</td>
            </tr>
        })
    }

    parseEntry(entry, type, fields){
        if(type && entry) return fields.reduce((acc, f) => {acc[f] = entry[type][f]; return acc;}, {});
        else return null;
    }

    buildBody(entries, findType){
        const {type, fields, headers} = findType;
        let unitCount = 0;
        const totals = {mrt: 0, crt: 0};
        const body = [];
        entries.forEach(([floorPlan, entries]) => {
            unitCount += entries.length;
            entries.forEach(e => {
                totals.mrt += parseFloat(e.market_rent);
                if(type && e[type]) totals.crt += parseFloat(e[type].current_rent);
                body.push({floor_plan: e.floor_plan, number: e.number, market_rent: e.market_rent, ...this.parseEntry(e, type, fields)});
            });
        }, []);
        return {body: body, unitCount: unitCount, headers: headers, totals: totals};
    }

    pdf(){
      const doc = new jsPDF('l', 'pt', 'a4');
      const pdfTitle = `Availability_Report ${this.props.start_date} - ${this.props.end_date}`;
      doc.text(pdfTitle, 40, 40)
      this.findType().forEach(t => {
        const title = this.declareType(t[0]);
        const {body, unitCount, headers, totals} = this.buildBody(sortByType(t[1], 'floor_plan'), title);
        const newHeaders = ["Floor Plan", "Units", "Market Rent"].concat(headers.map(h => h.label));
        const newFields = ["floor_plan", "number", "market_rent"].concat(title.fields);
        const newBody = body.map(b => newFields.map(f => b[f]));
        doc.text(t[0], 40, (doc.autoTable.previous.finalY || 40) + 40);
        doc.autoTable({
          startY: (doc.autoTable.previous.finalY || 40) + 50,
          head: [newHeaders],
          body: newBody,
          theme: 'grid',
          headStyles: {fillColor: [5, 55, 135]},
          columnStyles: {},
          didDrawPageContent: function (data) {
            doc.text(headerString, 40, 30);
          }
        })
      })
      doc.save(`${pdfTitle}.pdf`)
    }

    csv(){
      const title = `Availability_Report ${this.props.start_date} - ${this.props.end_date}`;
      const body = this.findType().reduce((acc, t) => {
        const title = this.declareType(t[0]);
        const {body, unitCount, headers, totals} = this.buildBody(sortByType(t[1], 'floor_plan'), title);
        const newHeaders = ["Floor Plan", "Units", "Market Rent"].concat(headers.map(h => h.label));
        const newFields = ["floor_plan", "number", "market_rent"].concat(title.fields);
        acc.push([t[0], "", ""].concat(headers.map(() => "")), newHeaders);
        acc = acc.concat(body.map(b => newFields.map(f => b[f])));
        return acc;
      }, [])
      return {csvTitle: title, csvBody: body};
    }

    render(){
        const {sortedEntries, modal} = this.state;
        return <div>
          {this.findType().map((t, i) => {
              const type = this.declareType(t[0]);
              const entries = sortByType(t[1], 'floor_plan');
              return <BoxScoreType key={i} title={t[0]} entries={this.buildBody(entries, type)} overView={this.buildOverview(t[0])}/>
          })}
        <Modal isOpen={modal} size="lg" toggle={this.toggleModal.bind(this, null)}>
            {sortedEntries && sortByType(sortedEntries, 'status').map( (sE, i) => {
                const type = this.declareType(sE[0]);
                const entries = sortByType(sE[1], 'floor_plan');
                return <BoxScoreType key={`modal-${i}`} title={`${sE[0]} -- ${sE[1][0].floor_plan}`} entries={this.buildBody(entries, type)} overView={this.buildOverview(sE[0])} noOverview={true}/>
            })}
        </Modal>
        </div>
    }
}


class BoxScoreType extends Component{
    constructor(props){
        super(props);
        this.state = {
            filters: {number: "desc", floor_plan: false, start_date: false, end_date: false, market_rent: false, current_rent: false, actual_move_in: false},
            noOverview: props.noOverview || false
        }
    }
    // state = {filters: {number: "desc", floor_plan: false, start_date: false, end_date: false, market_rent: false, current_rent: false, actual_move_in: false}};

    setFilters(filter){
        const newFilter = {...this.state.filters};
        Object.keys(newFilter).forEach(fKey => {
            if(fKey === filter && newFilter[fKey] === "asc") { newFilter[fKey] = "desc" ; return;}
            fKey === filter ? newFilter[fKey] = "asc" : newFilter[fKey] = false;
        });

        this.setState({filters: newFilter});
    }

    sort(){
        const {filters} = this.state;
        const filter = Object.keys(filters).find(f => filters[f]);
        if(filter.includes("date") || filter.includes("actual_move")){
            return filters[filter] === "asc" ? (a,b) => moment(a[filter]) - moment(b[filter]) : (a,b) => moment(b[filter]) - moment(a[filter])
        }else{
            return filters[filter] === "asc" ? (a,b) => b[filter] - a[filter] : (a,b) => a[filter] - b[filter]
        }
    }

    sortCollection(body){
        const {title} = this.props;
        return body.sort(this.sort()).map((b, i) => {
            const keys = Object.keys(b);
            return <tr key={`${title} ${i}`}>
                {keys.map(k => <td>{k.includes("rent") ? toCurr(b[k]) : b[k]}</td>)}
            </tr>
        });

    }

    findSortIcon(type){
        const {filters} = this.state;
        if(!filters[type]) return <i className="fas fa-sort" />;
        return filters[type] === "desc" ? <i className="fas fa-sort-down" /> : <i className="fas fa-sort-up" />;
    }

    buildFooter(crt, headers){
        return headers && headers.map((h,i) => h === "Current Rent" ? <td className="font-weight-bold">{toCurr(crt)}</td> : <td></td>)
    }

    toggleOverview(field){
        this.setState({[field]: !this.state[field]});
    }

    render(){
        const {overview, collapse, noOverview, floorPlan} = this.state;
        const {title, entries, overView} = this.props;
        const {unitCount, body, headers, totals} = entries;
        return <div className="p-2 m-2">
          <h4 className="text-muted ml-2">
              <a className="mr-2" onClick={!noOverview && this.toggleOverview.bind(this, "collapse")}>{title}</a>
              {!noOverview && <a className="lease-show" onClick={this.toggleOverview.bind(this, "overview")} style={overview ? {color: "#38a250"} : {}}>Overview</a>}
          </h4>
          <Collapse isOpen={!collapse}>
              <Table>
                <thead>
                    <tr>
                        <th>Floor Plan</th>
                        <th>Units ({unitCount}) {overview && <a onClick={this.setFilters.bind(this, "number")}>{this.findSortIcon("number")}</a>}</th>
                        <th>Market Rent {overview && <a onClick={this.setFilters.bind(this, "market_rent")}>{this.findSortIcon("market_rent")}</a>}</th>
                        {(overview || noOverview)&& headers && headers.map((header, i) => <th>{header.label} {header.sort && <a onClick={this.setFilters.bind(this, header.sort)}>{this.findSortIcon(header.sort)}</a>}</th>)}
                    </tr>
                </thead>
                <tbody>
                    {overview || noOverview ? this.sortCollection(body) : overView}
                </tbody>
                <tfoot>
                    <tr>
                        <td className="font-weight-bold">Totals</td>
                        <td className="font-weight-bold">{unitCount}</td>
                        <td className="font-weight-bold">{toCurr(totals.mrt)}</td>
                        {overview || noOverview && this.buildFooter(totals.crt, headers)}
                    </tr>
                </tfoot>
            </Table>
          </Collapse>
    </div>;
    }
}

export default BoxScore;
