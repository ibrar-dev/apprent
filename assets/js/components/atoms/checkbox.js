import React, {useState} from "react";
import styled from "styled-components";
import {CheckboxSvg} from "../icons";

const Checkbox = ({
  checked,
  label,
  onClick,
  disabled,
  indeterminate,
}) => {
  const [isHover, setIsHover] = useState(false);

  return (
    <div
      onClick={disabled ? () => {} : onClick}
      className={`inline-flex items-center ${disabled ? "cursor-default" : "cursor-pointer"}`}
      onMouseEnter={() => setIsHover(true)}
      onMouseLeave={() => setIsHover(false)}
    >
      <CheckboxSvg
        checked={checked}
        hover={isHover}
        disabled={disabled}
        indeterminate={indeterminate}
      />
      <Label>
        {label}
      </Label>
    </div>
  );
};

const Label = styled.div`
  font-weight: 400;
  font-style: normal;
  font-size: 14px;
  line-height: 16.8px;
  color: #04333B;
  margin-left: 8px;
`;

export default Checkbox;
