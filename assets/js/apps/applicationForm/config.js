import React from 'react';
import {Collection, Person, Pet, MoveIn, Contact, History, Employment, Vehicle, Income, Document} from './models';
import Occupants from './components/occupants';
import MoveInForm from './components/moveIn';
import Pets from './components/pets';
import Vehicles from './components/vehicles';
import Histories from './components/histories';
import Contacts from './components/contacts';
import Employments from './components/employments';
import Documents from './components/documents';
import Review from './components/review';
import Address from './models/address';

const blankConfig = (property) => {
  const prospect = window.PROSPECT_PARAMS || {};
  const residency = {};
  if (prospect.address) {
    residency.address = new Address();
    const {street, ...addr} = prospect.address;
    addr.address = street;
    Object.keys(addr).forEach(field => residency.address.set(field, addr[field]));
  }
  const occupants = new Collection(Person, [{
    status: 'Lease Holder',
    full_name: prospect.name,
    email: prospect.email,
    home_phone: prospect.phone
  }])
  return {
    occupants: {
      data: occupants,
      label: 'Occupants',
      component: <Occupants/>
    },
    move_in: {
      data: new MoveIn(),
      label: 'Move In Information',
      component: <MoveInForm/>
    },
    pets: {
      data: new Collection(Pet),
      label: 'Pets',
      component: <Pets/>
    },
    vehicles: {
      data: new Collection(Vehicle),
      label: 'Vehicles',
      component: <Vehicles/>
    },
    histories: {
      data: new Collection(History, [residency]),
      label: 'Previous Residency',
      component: <Histories/>
    },
    employments: {
      data: new Collection(Employment, [{}]),
      label: 'Employment Information',
      component: <Employments/>
    },
    income: {
      data: new Income(),
      component: null
    },
    emergency_contacts: {
      data: new Collection(Contact, [{validationData: {occupants}}]),
      label: 'Emergency Contacts',
      component: <Contacts/>
    },
    documents: {
      data: new Collection(
        Document,
        [
          {type: "Driver's License", validationData: {property}},
          {type: "Pay Stub", validationData: {property}}
        ]
      ),
      label: 'Upload Documents',
      component: <Documents/>
    },
    review: {
      data: {hasErrors: () => false},
      label: 'Review',
      component: <Review/>
    }
  };
};

const extract = (field, property = null) => {
  const data = {};
  const config = blankConfig(property);
  Object.keys(config).forEach((key) => data[key] = config[key][field]);
  return data;
};

export {extract};
