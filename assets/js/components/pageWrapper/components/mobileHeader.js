import React from "react";
import styled from "styled-components";
import {ApprentTextSvg, MenuSvg} from "../../icons";

const MobileHeader = ({onMenuToggle}) => (
  <Wrapper>
    <MenuSvg onClick={onMenuToggle} />
    <ApprentTextSvg />
    <div />
  </Wrapper>
);

const Wrapper = styled.div`
  background-color: #04333B;
  height: 50px;
  width: 100%;
  display: flex;
  padding-left: 19px;
  padding-right: 19px;
  justify-content: space-between;
  align-items: center;
  z-index: 2;

  position: fixed;
  top: 0px;
  left: 0px;

  &:before {
    content: "";
    position: absolute;
    
    background-color: transparent;
    bottom: -50px;
    margin-left: 5px;
    margin-right: 5px;
    left: 0px;
    height: 50px;
    width: calc(100% - 10px);
    border-top-left-radius: 30px;
    border-top-right-radius: 30px;
    box-shadow: 0 -10px 0 7px #04333B;
    pointer-events: none;
  }
`;

export default MobileHeader;
