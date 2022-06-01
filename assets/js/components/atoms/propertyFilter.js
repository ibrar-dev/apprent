import React, {useEffect, useState} from "react";
import {getCookie, setCookie} from "../../utils/cookies";
import PropertyFilterRow from "./propertyFilterRow";
import SelectedPropertyFilter from "./selectedPropertyFilter";
import Filter from "./filter";

const {properties} = window;
const firstProperty = properties[0];
const propertyIds = properties.map(({id}) => id);

// Pull selected property/properties, in order of precedence:
// - query params - `?property=123,456,789
// - cookie
// - first property in available properties list
const selectedProperties = () => {
  const queryParams = new URLSearchParams(window.location.search).get("selected_properties");

  if (queryParams) {
    // Query params is "123,345,789" -> we want that to become [123, 345, 456],
    // and we have to account for NaN, etc., in the possibilities
    const candidateIds = queryParams.split(",").filter((id) => id.match(/^\d+$/)).map((id) => Number(id));
    const matchedIds = candidateIds.filter((id) => propertyIds.includes(id));

    // Return, but only if we have a match; otherwise, flow through to cookie,
    // then default
    if (matchedIds.length > 0) return matchedIds;
  }

  const propertyListFromCookie = getCookie("multiPropertySelector");
  if (propertyListFromCookie) return propertyListFromCookie.split(",");

  return [firstProperty.id];
};

const PropertyFilter = ({onPerformUpdate, onClearList}) => {
  const adminProperties = properties;
  const [selected, setSelected] = useState([]);
  const [searchPropertyValue, setSearchPropertyValue] = useState("");

  useEffect(() => {
    updateSelected(selectedProperties().map(num => Number(num)));
  }, []);

  const filteredProperties = adminProperties?.filter((p) => (
    p.name.toLowerCase().indexOf(searchPropertyValue.toLowerCase()) > -1));

  // Update selected properties -- `selected` is an array of 0 or more integer
  // primary key IDs for properties.
  const updateSelected = (newSelected) => {
    setSelected(newSelected);
    setCookie("multiPropertySelector", newSelected.toString());
    // Set URL query params for a shareable link - replaces in place rather than
    // triggering a new page-load
    const query = new URLSearchParams(window.location.search);
    query.set("selected_properties", newSelected);
    window.history.replaceState({}, "", `${location.pathname}?${query}`);
    onClearList();
    newSelected.length && onPerformUpdate()
  };

  const toggleSelected = (id) => {
    const newSelected = selected.includes(id)
      ? selected.filter((item) => item !== id)
      : [...selected, id];
    updateSelected(newSelected);
  };

  const propertyFilterRows = filteredProperties.map((property) => (
    <PropertyFilterRow
      key={property.id}
      property={property}
      onClick={toggleSelected}
      selected={selected.indexOf(property.id) > -1}
    />
  ));

  const topList = selected.map((id) => {
    const property = adminProperties.find(({id: propertyId}) => propertyId === id);
    if (property) {
      return (
        <SelectedPropertyFilter
          key={property.id}
          property={property}
          onClose={toggleSelected}
        />
      );
    }
    return (<div />);
  });

  return (
    <Filter
      topList={topList}
      placeholder="Select a property"
      showListHeader
      showSearch
      searchValue={searchPropertyValue}
      onSearch={setSearchPropertyValue}
      onClear={() => updateSelected([])}
      onSelectAll={() => updateSelected(propertyIds)}
      label="Filter by property:"
    >
      {propertyFilterRows}
    </Filter>
  );
};

export default PropertyFilter;
