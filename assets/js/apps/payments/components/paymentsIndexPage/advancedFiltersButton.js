// import {SwitchButton} from "atoms";
import React, {useEffect, useRef, useState} from "react";
import styled from "styled-components";
import {SettingsWheelSvg} from "../../../../components/icons";
import Filters from "./filters";

const AdvancedFilterButton = ({
  filters,
  onChangeFilters,
}) => {
  const wrapperRef = useRef(null);

  const [hovered, setHovered] = useState(false);
  const [active, setIsActive] = useState(false);

  useEffect(() => {
    function handleClickOutside(event) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        setIsActive(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [wrapperRef]);

  return (
    <DropDown ref={wrapperRef}>
      <DropDownButton
        onMouseEnter={() => { setHovered(true); }}
        onMouseLeave={() => (setHovered(false))}
        onClick={() => setIsActive(true)}
      >
        <Text className="mr-2">Advanced Filters:</Text>
        <SettingsWheelSvg hovered={hovered || active} />
      </DropDownButton>
      {active
        && (
        <DropDownContent>
          <Filters
            filters={filters}
            onChange={onChangeFilters}
          />
        </DropDownContent>
        )}
    </DropDown>
  );
};

const Text = styled.div`
  font-weight: 600;
  font-size: 12px;
  color: #04333B;
`;

const DropDownContent = styled.div`
  position: absolute;
  background-color: #f1f1f1;
  width: 260px;
  
  background: #FFFFFF;

  border: 1px solid #E3E3E3;
  box-sizing: border-box;

  box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.08);
  border-radius: 12px;

  z-index: 10;

  padding: 20px;
  margin-top: 5px;
`;

const DropDown = styled.div`
`;

const DropDownButton = styled.div`
  display: flex;
  align-items: center;
  cursor: pointer;
`;

export default AdvancedFilterButton;
