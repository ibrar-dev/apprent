import React, {useEffect, useState, useRef} from 'react';
import classset from "classnames";
import GoogleAutocomplete, {geocodeByPlaceId} from 'react-google-places-autocomplete';
import StateSelect from './stateSelect';
import store from '../../store';

function getAddress(parts) {
  return parts.filter(p => p.types.includes("street_number") || p.types.includes("route")).map(a => a.long_name).join(" ");
}

function getType(parts, desiredType, desiredField) {
  const part =  parts.find(p => p.types.find(t => t === desiredType))

  // handle when a field can't be found
  if (part) {
    return part[desiredField]
  } else {
    return part
  }
}

// For NYC Boroughs, for example, we sometimes do not have the city name and
// instead use the borough name. This code handles that case
function getCity(parts) {
  let locality = getType(parts, "locality", "long_name")
  let sublocality = getType(parts, "sublocality", "long_name")
  let neighborhood = getType(parts, "neighborhood", "long_name")

  return locality || sublocality || neighborhood
}

function fillInAddress(addressComponents) {
  return {
    address: getAddress(addressComponents),
    city: getCity(addressComponents),
    state: getType(addressComponents, "administrative_area_level_1", "short_name"),
    zip: getType(addressComponents, "postal_code", "long_name")
  }
}

export default function Address(name, value, error = {}, {component}) {
  const lang = store.getState().language;
  const setAddressField = (e) => {
    const newVal = {...value, [e.target.name]: e.target.value};
    const event = {target: {value: newVal, name}};
    component.editField.call(component, event);
  };

  function placeSelected({place_id}) {
    geocodeByPlaceId(place_id).then(r => {
      const address = fillInAddress(r[0].address_components);
      for (const [key, value] of Object.entries(address)) {
        setAddressField({target: {name: key, value: value}})
      }
    })
  }

  return (
    <div>
      <div className="row">
        <div className="col-lg-8">
          <div className="labeled-box">
            <GoogleAutocomplete
              initialValue={value.address ? value.address : ""}
              inputClassName={classset({"form-control": true, 'is-invalid': lang[error.address]})}
              placeholder={""}
              suggestionsClassNames={{container: 'border border-primary', suggestion: 'ml-1 mt-1 cursor-pointer'}}
              onSelect={p => placeSelected(p)} />
            <div className="labeled-box-label">Address</div>
          </div>
          {error.address && <em className="error invalid-feedback">{lang[error.address]}</em>}
        </div>
        <div className="col-lg-4 no-left-pad">
          <div className="labeled-box">
          <input className={classset({"form-control": true, 'is-invalid': lang[error.unit]})}
                 name="unit"
                 value={value.unit}
                 onChange={setAddressField.bind(this)}/>
            <div className="labeled-box-label">Unit #</div>
          </div>
        </div>
      </div>
      <div className="row">
        <div className="col-lg-5">
          <div className="labeled-box">
          <input className={classset({"form-control": true, 'is-invalid': lang[error.city]})}
                 name="city"
                 value={value.city}
                 onChange={setAddressField.bind(this)}/>
            <div className="labeled-box-label">City</div>
          </div>
          {error.city && <em className="error invalid-feedback">{lang[error.city]}</em>}
        </div>
        <div className="col-lg-3 no-left-pad">
          <div className="labeled-box">
          <StateSelect value={value.state}
                       name="state"
                       error={error.state}
                       onChange={setAddressField.bind(this)}/>
            <div className="labeled-box-label">State</div>
          </div>
          {error.state && <em className="error invalid-feedback">{lang[error.state]}</em>}
        </div>
        <div className="col-lg-4 no-left-pad">
          <div className="labeled-box">
          <input className={classset({"form-control": true, 'is-invalid': lang[error.zip]})}
                 name="zip"
                 value={value.zip}
                 onChange={setAddressField.bind(this)}/>
            <div className="labeled-box-label">ZIP</div>
          </div>
          {error.zip && <em className="error invalid-feedback">{lang[error.zip]}</em>}
        </div>
      </div>
    </div>
  );
}
