import React, {useEffect, useState} from 'react';
import {Drawer, List, Popconfirm, Button, Tag, Space} from 'antd';
import axios from 'axios';
import TagsInput from 'react-tagsinput';
import {safeRegExp} from "../../../../../utils";
import {CarTwoTone} from "@ant-design/icons";
import actions from "../../../actions";

function descriptionRender(vendor, category, setCategory) {
  return <Space direction="horizontal">
    {vendor.categories.map(c => (
      <Tag className="cursor-pointer"
           onClick={() => setCategory(`${vendor.id}-${c.name}`)}
           color={category === `${vendor.id}-${c.name}` ? "green" : "volcano"} key={c.id}>
        {c.name}
      </Tag>
    ))}
  </Space>
}

function filteredVendors(orders, vendors, tags) {
  return vendors.filter(v => {
    return checkVendor(v, orders) && checkTags(v, tags)
  })
}

function checkTags(vendor, tags) {
  const checked = tags.map(t => checkTag(vendor, t));
  return checked.every(t => t === true)
}

function checkTag(vendor, tag) {
  const filter = safeRegExp(tag);
  return filter.test(vendor.name)
}

function checkVendor(vendor, orders) {
  return orders.filter(o => checkVendorOrder(vendor, o)).length === orders.length;
}

function checkVendorOrder(vendor, order) {
  if (!vendor || !vendor.categories.length || !vendor.property_ids.length) return false;
  return vendor.property_ids.includes(order.property_id)
}

function getVendorFromCategory(category, id) {
  if (!category) return false;
  const vendor = category.split("-")[0];
  return parseInt(vendor) === id
}
//this.props.orders.map((x) => {x["vendor_id"] = selectedVendor.id; x["category_id"] = selectedCategory.id; x["status"] = 'Open' })

function getSingleCategory(vendor) {
  if (vendor.categories.length === 1) return vendor.categories[0]
  return false
}

function confirmOutsource(vendor, category, selected, onCloseAndClear) {
  const category_id = getSingleCategory(vendor) ? getSingleCategory(vendor) : vendor.categories.filter(c => c.name === category.split("-")[1])[0];
  const orders = selected.map((o) => {
    const params = {vendor_id: vendor.id, category_id: category_id.id, status: "Open"}
    return {...o, ...params}
  });
  actions.outsourceOrders(orders);
  onCloseAndClear();
}

function shouldDisableVendor(vendor, category) {
  if (vendor.categories.length === 1) return false;
  if (!category) return true;
  const parsed = category.split("-")[0];
  return parseInt(parsed) !== vendor.id;
}

const OutsourceDrawer = ({selected, visible, close, closeAndClear}) => {
  const [vendors, setVendors] = useState([]);
  const [fetching, setFetching] = useState(false);
  const [tags, setTags] = useState([]);
  const [category, setCategory] = useState(null);

  useEffect(() => {
    const fetchVendors = async () => {
      setFetching(true);
      const result = await axios('/api/vendors');
      setVendors(result.data);
      setFetching(false);
    };

    fetchVendors()
  }, []);

  return (
    <Drawer
      title="Outsource to Vendor"
      placement="left"
      width={760}
      onClose={close}
      visible={visible}
      closable
    >
      <TagsInput
        value={tags}
        onChange={setTags}
        onlyUnique
        className="react-tagsinput"
        inputProps={{className: 'react-tagsinput-input', placeholder: 'Add a search term', style: {width: 'auto'}}}
      />
      <List
        itemLayout="horizontal"
        loading={fetching}
        size="small"
        pagination={{defaultPageSize: 50, position: "top"}}
        dataSource={filteredVendors(selected, vendors, tags)}
        renderItem={
          (v) => (
            <List.Item
              extra={(
                <Popconfirm
                  disabled={shouldDisableVendor(v, category)}
                  title={`Assign these ${selected.length} orders to ${v.name}`}
                  onConfirm={() => confirmOutsource(v, category, selected, closeAndClear)}
                >
                  <Button
                    ghost
                    shape="circle"
                    icon={(
                      <CarTwoTone
                        size={48}
                        twoToneColor={getVendorFromCategory(category, v.id) ? "#28a745" : "#d9534f"}
                      />
                    )}
                  />
                </Popconfirm>
              )}
            >
              <List.Item.Meta
                title={v.name}
                description={descriptionRender(v, category, setCategory)}
              />
            </List.Item>
          )
        }
      />
    </Drawer>
  );
};

export default OutsourceDrawer;
