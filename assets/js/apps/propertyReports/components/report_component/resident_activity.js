import {Component} from "react";
import React from "react";
import Lease from './lease'
import {Col, Row} from "reactstrap";
import moment from "moment";
import {toCurr} from "../../../../utils";

class ResidentActivity extends Component {
    state={modal: false, leases: [], in: '#475f78', out: '#475f78', trans: '#475f78', renew: '#475f78', month: '#475f78', evict: '#475f78'}

    hover(field, property){
        this.setState({[field]: property})
    }

    showLeases(props, type){
        this.setState({...this.state, modal: true, leases: props, type: type})
    }

    toggleModal(){
        this.setState({...this.state, modal: !this.state.modal})
    }

    movedInfo(leases, type){
        return leases.map(l => {
            return <Row key={l.id}>
                <Col>{l.number}</Col>
                <Col>
                    {l.tenants.length ? l.tenants.map(t => {
                        return <Row key={t.id}><a href={`/tenants/${t.id}`} target="_blank">{t.first_name} {t.last_name}</a></Row>
                    }) : null}
                </Col>
                <Col>{l.floor_plan_name}</Col>
                <Col>{l.rent_amount && l.rent_amount.map(r => {
                    return <Row><strong>{r.name}: {toCurr(r.amount)}</strong></Row>
                    })}
                </Col>
                {/*<Col>{moment(l.lease.start_date).format("MM-DD-YYYY")}</Col>*/}
                {type === "Moved Out" ? <Col>{moment(l.lease[0].actual_move_out).format("MM-DD-YYYY")}</Col> : <Col>{moment(l.lease[0].actual_move_in).format("MM-DD-YYYY")}</Col>}
            </Row>
        })
    }

    transInfos(leases, type){
        return leases.map(l => {
            return <Row key={l.id}>
                <Col>{l.curr_lease.number}</Col>
                <Col>
                    {l.tenants.length ? l.tenants.map(t => <Row key={t.id}>
                            <a href={`/tenants/${t.id}`} target="_blank">{t.first_name} {t.last_name}</a>
                    </Row>) : null}
                </Col>
                <Col>{l.floor_plan_name}</Col>
                <Col>{l.rent_amount && l.rent_amount.map(r => {
                    return <Row><strong>{r.name}: {toCurr(r.amount)}</strong></Row>
                })}
                </Col>
                <Col>{moment(l.start_date).format("MM-DD-YYYY")}</Col>
                <Col>{moment(l.end_date).format("MM-DD-YYYY")}</Col>
            </Row>
        })
    }

    renewInfo(leases, type){
        return leases.map( l => {
            return <Row key={l.id}>
                <Col>{l.number}</Col>
                {/*<Col>{l.tenant_id ? <a href={`/tenants/${l.tenant_id}`}>{l.first_name} {l.last_name}</a> : <>{l.first_name} {l.last_name}</>}</Col>*/}
                <Col>
                    {l.tenants.length ? l.tenants.map(t => <Row key={t.id}>
                        <a href={`/tenants/${t.id}`} target="_blank">{t.first_name} {t.last_name}</a>
                    </Row>) : null}
                </Col>
                <Col>{l.floor_plan_name}</Col>
                <Col>{l.rent_amount && l.rent_amount.map(r => {
                    return <Row><strong>{r.name}: {toCurr(r.amount)}</strong></Row>
                })}
                </Col>
                <Col>{moment(l.lease[0].start_date).format("MM-DD-YYYY")}</Col>
                <Col>{moment(l.lease[0].end_date).format("MM-DD-YYYY")}</Col>
            </Row>
        })
    }

    monthInfo(leases, type){
        return leases.map(l => {
            return <Row key={l.id}>
                <Col>{l.number}</Col>
                {/*<Col>{l.tenant_id ? <a href={`/tenants/${l.tenant_id}`}>{l.first_name} {l.last_name}</a> : <>{l.first_name} {l.last_name}</>}</Col>*/}
                <Col>
                    {l.tenants && l.tenants.map(t => <Row key={t.id}>
                        <a href={`/tenants/${t.id}`} target="_blank">{t.first_name} {t.last_name}</a>
                    </Row>)}
                </Col>
                <Col>{l.floor_plan_name}</Col>
                <Col>{l.lease && l.lease.rent_amount.map(r => {
                    return <Row><strong>{r.name}: {toCurr(r.amount)}</strong></Row>
                })}
                </Col>
                <Col>{moment(l.end_date).format("MM-DD-YY")}</Col>
            </Row>
        });
    }

    evictions(leases, type){
        return leases.map(l => {
            return <Row key={l.id}>
                <Col>{l.number}</Col>
                {/*<Col>{l && l.tenant_id ? <a href={`/tenants/${l.tenant_id}`} target="_blank">{l.first_name} {l.last_name}</a> : <>{l.first_name} {l.last_name}</>}</Col>*/}
                <Col>
                    {l.tenants.length ? l.tenants.map(t => <Row key={t.id}>
                        <a href={`/tenants/${t.id}`} target="_blank">{t.first_name} {t.last_name}</a>
                    </Row>) : null}
                </Col>
                <Col>{l.floor_plan_name}</Col>
                {/*<Col>{l.rent_amount}</Col>*/}
                <Col>{moment(l.evict_date).format("MM-DD-YY")}</Col>
            </Row>
        });
    }

    getData(leases, type){
        switch(type){
            case "Moved In":
                return this.movedInfo.bind(this, leases, type);
            case "Moved Out":
                return this.movedInfo.bind(this, leases, type);
            case "Onsite-Transfer":
                return this.transInfos.bind(this, leases, type);
            case "Renewal":
                return this.renewInfo.bind(this, leases, type);
            case "Month To Month":
                return this.monthInfo.bind(this, leases, type);
            case "Evictions":
                return this.evictions.bind(this, leases, type);
            default:
                return;
        }
    }

    render(){
        const {res_act} = this.props;
        const {modal, leases, type} = this.state;
        return <tr>
            <td>{res_act.type}</td>
            <td>{res_act.total}</td>
            <td>
                <a style={{color: this.state.in}}
                   onClick={res_act.movedIn.length ? this.showLeases.bind(this, res_act.movedIn, "Moved In") : null}
                   onMouseEnter={this.hover.bind(this, 'in', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'in', '#475f78')}>{res_act.movedIn.length}</a>
            </td>
            <td>
                <a style={{color: this.state.out}}
                   onClick={res_act.movedOut.length ? this.showLeases.bind(this, res_act.movedOut, "Moved Out") : null}
                   onMouseEnter={this.hover.bind(this, 'out', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'out', '#475f78')}>{res_act.movedOut.length}</a>
            </td>
            <td>
                <a style={{color: this.state.trans}}
                   onClick={res_act.transfer.length ? this.showLeases.bind(this, res_act.transfer, "Onsite-Transfer") : null}
                   onMouseEnter={this.hover.bind(this, 'trans', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'trans', '#475f78')}>{res_act.transfer.length}</a>
            </td>
            <td>
                <a style={{color: this.state.renew}}
                   onClick={res_act.renewal.length ? this.showLeases.bind(this, res_act.renewal, "Renewal") : null}
                   onMouseEnter={this.hover.bind(this, 'renew', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'renew', '#475f78')}>{res_act.renewal.length}</a>
            </td>
            <td>
                <a style={{color: this.state.month}}
                   onClick={res_act.month ? this.showLeases.bind(this, res_act.month, "Month To Month") : null}
                   onMouseEnter={this.hover.bind(this, 'month', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'month', '#475f78')}>{res_act.month.length}</a>
            </td>
            <td>
                <a style={{color: this.state.evict}}
                   onClick={res_act.evictions ? this.showLeases.bind(this, res_act.evictions, "Evictions") : null}
                   onMouseEnter={this.hover.bind(this, 'evict', '#0056b3')}
                   onMouseLeave={this.hover.bind(this, 'evict', '#475f78')}>{res_act.evictions.length}</a>
            </td>
            <Lease getData={this.getData(leases, type)} type={type} modal={modal} leases={leases} toggle={this.toggleModal.bind(this)}/>
        </tr>
    }
}

export default ResidentActivity;