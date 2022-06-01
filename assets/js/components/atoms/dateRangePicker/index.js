import React, {useState, useEffect, useRef} from "react";
import {DatePicker} from "antd";
import Wrapper from "../filter/components/Wrapper";
import Label from "../filter/components/Label";
import {DownCaretSvg} from "../../icons";

const {RangePicker} = DatePicker;

const DateRangePicker = ({dateFilter, onChangeDateFilter}) => {
  const [isOpen, setIsOpen] = useState(false);
  const wrapperRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        !clickInCalendar(event) && setIsOpen(false)
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [wrapperRef]);

  // click events inside of our open datepicker appear outside of the wrapperRef
  // this function helps us identify these events
  const clickInCalendar = ({target: {className, tagName}}) => {
    const splitClassName = typeof className === "string" ? className.split("-") : null;
    const targetClassName = splitClassName ? splitClassName[0] : null;
    return targetClassName === "ant" || tagName === "INPUT" || tagName === "svg";
  };

  const toggleModal = (event) => {
    clickInCalendar(event) ? setIsOpen(true) : setIsOpen(!isOpen);
  };

  return (
    <div ref={wrapperRef}>
      <Wrapper onClick={(e) => toggleModal(e)}>
        <div className="flex items-center">
          <Label bold className="mr-1">
            Filter by Date:
          </Label>
          <RangePicker
            defaultValue={dateFilter}
            size="small"
            open={isOpen}
            allowClear={false}
            suffixIcon={null}
            bordered={false}
            onChange={onChangeDateFilter}
          />
        </div>
        <div className="flex items-center">
          <DownCaretSvg />
        </div>
      </Wrapper>
    </div>
  );
};

export default DateRangePicker;
