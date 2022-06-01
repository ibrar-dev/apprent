import React, {useEffect, useState} from "react";
import {Select, Space, Avatar} from "antd";
import {getCookie, setCookie} from "../../utils/cookies";
import {safeRegExp} from "../../utils";

const {Option} = Select;

const properties = window.properties;
const firstProperty = properties[0];

function filterOptions(input, option) {
  return input.test(option.field)
}

function getTitle(name) {
  return name.split(" ").map(n => n[0]).join("").toUpperCase()
}

function getAvatar(p) {
  if (p.icon) return <Avatar size={"small"} src={p.icon}/>;
  return <Avatar size={"small"}>{getTitle(p.name)}</Avatar>
}

// Pull selected property/properties, in order of precedence:
// - query params - `?property=123,456,789
// - cookie
// - first property in available properties list
function selectedProperties() {
  const queryParams = new URLSearchParams(window.location.search).get("selected_properties")

  if (queryParams) {
    const propertyIds = properties.map((property) => property.id)

    // Query params is "123,345,789" -> we want that to become [123, 345, 456],
    // and we have to account for NaN, etc., in the possibilities
    const candidateIds = queryParams.split(",").filter((id) => id.match(/^\d+$/)).map((id) => parseInt(id))

    const matchedIds = candidateIds.filter((id) => propertyIds.includes(id))

    // Return, but only if we have a match; otherwise, flow through to cookie,
    // then default
    if (matchedIds.length > 0) {
      return matchedIds;
    }
  }

  const propertyListFromCookie = getCookie("multiPropertySelector");

  if (propertyListFromCookie) {
    return propertyListFromCookie.split(",")
  }

  return [firstProperty.id];
}

const MultiPropertySelect = ({selectProps, style, className, onChange}) => {
  const [selected, setSelected] = useState([]);
  const setSelectedValues = (v) => setSelected(v.map(i => parseInt(i)));

  useEffect(() => {
    setSelectedValues(selectedProperties());
  }, []);

  // Update selected properties -- `selected` is an array of 0 or more integer
  // primary key IDs for properties.
  useEffect(() => {
    setCookie("multiPropertySelector", selected.toString());

    // Set URL query params for a shareable link - replaces in place rather than
    // triggering a new page-load
    const query = new URLSearchParams(window.location.search)
    query.set("selected_properties", selected)
    window.history.replaceState({}, "", `${location.pathname}?${query}`);

    onChange(selected);
  }, [selected]);

  return (
    <div id={"property-multiselect-app"} style={style} className={className}>
      <Select
        showSearch
        {...selectProps}
        className={"w-100"}
        optionFilterProp="children"
        mode={"multiple"}
        size={"large"}
        value={selected.map(s => "" + s)}
        filterOption={(input, option) => {
          const filter = safeRegExp(input);
          return filterOptions(filter, option);
        }}
        onChange={setSelectedValues}
        optionLabelProp={"label"}
        placeholder={"Select a Property"}
      >
        {properties.map(p => {
          return <Option key={p.id} field={p.name} label={getAvatar(p)}>
            <Space size={"small"}>
              {getAvatar(p)}
              <span>{p.name}</span>
            </Space>
          </Option>
        })}
      </Select>
    </div>
  )
};

export default MultiPropertySelect;
