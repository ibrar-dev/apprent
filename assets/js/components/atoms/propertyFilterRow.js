import React, {useState} from "react";
import styled from "styled-components";
import Checkbox from "./checkbox";

const PropertyFilterRow = ({property: {name, icon, id}, selected, onClick}) => {
  const [imageError, setImageError] = useState(false);

  return (
    <Wrapper onClick={() => onClick(id)}>
      <Checkbox onClick={() => { }} checked={selected} />
      {!imageError
        && (
        <div className="mr-1.5">
          <Image onError={() => setImageError(true)} src={icon} />
        </div>
        )}
      {name}
    </Wrapper>
  );
};

const Wrapper = styled.div`
  color: #04333B;
  font-style: normal;
  font-weight: 400;
  font-size: 12px;
  line-height: 14px;
  padding: 13px;
  cursor: pointer;

  display: flex;
  align-items: center;

  &:hover {
    font-weight: 600;
  }
`;

const Image = styled.img`
  width: 14px;
  height: 14px;
  border-radius: 50%;
  object-fit: cover;
`;

export default PropertyFilterRow;
