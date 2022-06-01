import React, {useCallback, useState, useEffect} from "react";
import { Select, Space, Avatar, Spin } from "antd";
import { debounce } from "lodash";
import axios from "axios";

const { Option } = Select;

function unitLabel(option) {
  if (option.name) return option.name
  return "UNOCCUPIED"
}

function tenantLabel(option) {
  return option.name
}

function typeSwitcherLabel(option) {
  switch (option.type) {
    case "units":
      return unitLabel(option);
    case "tenants":
      return tenantLabel(option);
    default:
      return "";
  }
}

function typeSwitcherURL(option) {
  switch (option.type) {
    case "units":
      if (option.tenancy_id) return `/tenants/${option.tenancy_id}`;
      return `/${option.type}/${option.id}`;
    case "tenants":
      return `/${option.type}/${option.tenancy_id}`;
    default:
      return "";
  }
}

function getTitle(name) {
  console.log(name);
  return name.split(" ").map(n => n[0]).join("").toUpperCase()
}

function getAvatar(p) {
  if (p.icon) return <Avatar size={"small"} src={p.icon}/>;
  return <Avatar size={"small"}>{getTitle(p.name)}</Avatar>
}

function optionRender(option) {
  return (
    <Option key={typeSwitcherURL(option)}>
      <Space size="small">
        {getAvatar(option)}
        <span>{option.property} - {option.unit} ({typeSwitcherLabel(option)})</span>
      </Space>
    </Option>
  )
}


function tenantSearch() {
  const [loading, setLoading] = useState(false);
  const [term, setTerm] = useState("");
  const [options, setOptions] = useState([]);

  const delayedCall = useCallback(debounce(() => {
    if (term.length >= 1) {
      const fetchData = async () => {
        setLoading(true);
        const promise = axios.get(`/api/tenants?search=${term}`);
        promise.then((r) => {
          setOptions(r.data);        
        });
        promise.finally(() => {
          setLoading(false);
        })
      };
      fetchData()
    }
  }, 1000), [term])

  useEffect(() => {
    delayedCall();
    return () => delayedCall.cancel();
  }, [term]);

  function selectOption(option) {
    return window.location.href = option
  }

  return (
    <Select
      style={{width: '100%'}}
      placeholder="Search"
      loading={loading}
      onSearch={e => setTerm(e)}
      showSearch
      onSelect={e => selectOption(e)}
      notFoundContent={loading ? <Spin size="small" /> : null}
      filterOption={false}
      
    >
     {options.length && options.map((o) => {
       return optionRender(o);
     })}
    </Select>
  )
}

export default tenantSearch;