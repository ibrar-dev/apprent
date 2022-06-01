import React from "react";
import styled from "styled-components";

const SelectedPropertyFilter = ({property: {icon, id}, onClose}) => (
  <Wrapper>
    <ImageWrapper src={icon} />
    <div className="cursor-pointer ml-1.5" onClick={() => onClose(id)}>
      <svg width="12" height="12" viewBox="0 0 12 12" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M6 11C8.76142 11 11 8.76142 11 6C11 3.23858 8.76142 1 6 1C3.23858 1 1 3.23858 1 6C1 8.76142 3.23858 11 6 11Z" fill="#9EACB0" />
        <path d="M7.5 4.5L4.5 7.5" stroke="#F3F5F5" strokeLinecap="round" strokeLinejoin="round" />
        <path d="M4.5 4.5L7.5 7.5" stroke="#F3F5F5" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </div>
  </Wrapper>
);

const Wrapper = styled.div`
  width: 46px;
  height: 24px;

  display: flex;
  align-items: center;
  justify-content: center;

  background-color: #F3F5F5;
  border-radius: 20px;
`;

const ImageWrapper = styled.img`
  border-radius: 50%;
  width: 12px;
  height: 12px;
  object-fit: cover;
`;

export default SelectedPropertyFilter;
