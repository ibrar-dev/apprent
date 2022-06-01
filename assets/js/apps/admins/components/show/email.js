import React from "react";
import {connect} from "react-redux";
import {withRouter} from "react-router-dom";
import { FormGroup, Label, Input, CustomInput } from 'reactstrap';
import actions from "../../actions.js"
import EmailSubscriptions from "./emailSubscriptions";

class Email extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      propertyFilter: "",
    };
  }

  propertyFilter = (e) => {
    this.setState({propertyFilter: e.target.value});
  }

  toggleSubscription = (admin_id, property_id, type, e) => {
    const {checked} = e.target;
    if(checked) {
      actions.addInsightSubscription(property_id, admin_id, type)
    } else {
      const {insightSubscriptions} = this.props
      const subscription = insightSubscriptions.find(x => x.type == type && x.property_id == property_id)

      if (subscription) {
        actions.removeInsightSubscription(subscription.id, admin_id)
      }
    }
  }

  render() {
    const {activeAdmin, entities} = this.props;

    // Nothing loaded yet -- let's wait for it to load
    if (Object.keys(activeAdmin).length === 0) {
      return null;
    }

    const adminEntities = entities.filter((e) => activeAdmin.entity_ids.includes(e.id))
    const entityPropIds = adminEntities.map((e) => e.property_ids.filter(x => x))
    const uniqPropsIds = [].concat(...entityPropIds);

    const {insightSubscriptions} = this.props;

    // Given all properties and all subscriptions, determine whether the current
    // user is or is not subscribed to a single type of report for a single
    // property (but does this for all properties and all report types)
    const mappedSubscriptions = uniqPropsIds.reduce((accumulator, id) => {
      accumulator[`weekly-${id}`] = !!insightSubscriptions.find((x) => x.type == "weekly" && x.property_id == id)
      accumulator[`daily-${id}`] = !!insightSubscriptions.find((x) => x.type == "daily" && x.property_id == id)

      return accumulator
    }, {})

    const filteredProps = properties.filter(p => uniqPropsIds.includes(p.id))
    const {propertyFilter} = this.state;

    // Case-insensitive matching on a partial string
    const entityRegex = new RegExp(propertyFilter, "i");

    // If a filter is in place, we want only those names that match
    const matchedProps = filteredProps.filter((prop) => prop.name.match(entityRegex))

    return (
      <>
        <EmailSubscriptions activeAdmin={activeAdmin} />
        <div style={{padding: 30, paddingLeft: 30, paddingRight: 30}}>
          <h4 style={{color: "#97a4af"}}>Maintenance Reports</h4>
          <Input
            onChange={(e) => this.propertyFilter(e)}
            value={propertyFilter}
            placeholder="Filter by Property Name"
          />
          {
            matchedProps.map((property) => (
              <FormGroup key={property.id} className="mt-3 ml-3">
                <Label for="exampleCheckbox">{property.name}</Label>
                <div>
                  <CustomInput
                    inline
                    type="switch"
                    id={`weekly-${property.id}`}
                    name={`weekly-${property.id}`}
                    label="Weekly"
                    checked={mappedSubscriptions[`weekly-${property.id}`]}
                    onChange={(e) => this.toggleSubscription(activeAdmin.id, property.id, 'weekly', e)}
                  />
                  <CustomInput
                    inline
                    type="switch"
                    id={`daily-${property.id}`}
                    name={`daily-${property.id}`}
                    label="Daily"
                    checked={mappedSubscriptions[`daily-${property.id}`]}
                    onChange={(e) => this.toggleSubscription(activeAdmin.id, property.id, 'daily', e)}
                  />
                </div>
              </FormGroup>
            ))
          }
        </div>
      </>
    )
  }
}

export default withRouter(connect(({entities, activeAdmin, insightSubscriptions}) => {
  return {entities, activeAdmin, insightSubscriptions};
})(Email));
