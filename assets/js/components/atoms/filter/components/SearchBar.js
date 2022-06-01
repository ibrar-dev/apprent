import React from "react";
import styled from "styled-components";
import MagnifyingGlassSvg from "../../../icons/magnifyingGlass";

const SearchBar = ({value, onChange}) => (
  <Wrapper>
    <Input
      autoFocus
      value={value}
      onChange={onChange}
      placeholder="Search"
    />
    <div className="absolute right-3">
      <MagnifyingGlassSvg color="#04333B" />
    </div>
  </Wrapper>
);

const Wrapper = styled.div`
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  
  position: relative;
`;

const Input = styled.input`
  outline: none;
  height: 100%;
  width: 100%;

  padding-left: 12px;
  padding-right: 12px;
  
  background-color: #F7F7F7;
  border: 1px solid #E3E3E3;

  &:focus{
    background-color: #FFFFFF;
    border: 1px solid #1DBD6B;
  }
`;

export default SearchBar;