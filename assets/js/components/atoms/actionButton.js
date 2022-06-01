import React, {useState} from "react";
import styled, {css} from "styled-components";
import {IButtonTypeEnum} from "./utils/enums";
import {ButtonHoverSvg} from "../icons";

const ActionButton = ({
  big, onClick, title, type, disabled, icon,
}) => {
  const [isHover, setIsHover] = useState(false);
  const [isActive, setIsActive] = useState(false);

  return (
    <ButtonWrapper
      onClick={onClick}
      big={big}
      buttonType={type || IButtonTypeEnum.Solid}
      onMouseEnter={() => setIsHover(true)}
      onMouseLeave={() => setIsHover(false)}
      onMouseUp={() => setIsActive(false)}
      onMouseDown={() => setIsActive(true)}
      disabled={disabled}
    >
      {isHover && !isActive && type !== IButtonTypeEnum.Text
        && (
        <div className="absolute left-1/2 transform -translate-x-1/2 bottom-0">
          <ButtonHoverSvg big={big} color={type === IButtonTypeEnum.Outlined ? "dark" : "white"} />
        </div>
        )}
      {icon
        && (
        <div className="mr-2">
          {icon}
        </div>
        )}
      {title}
    </ButtonWrapper>
  );
};

const ButtonWrapper = styled.button`
  padding: ${(p) => (p.big ? "8px 20px" : "4px 20px")};
  font-size: 14px;
  border-radius: 60px;
  outline: none;
  position: relative;

  ${(p) => p.buttonType === IButtonTypeEnum.Solid && css`
    background-color: #1DBD6B;
    border: 1px solid #1DBD6B;
    color: white;
    font-weight: 600;

    &:active {
    background-color: #0D5530;
    border: 1px solid #0D5530;
    }

    &:disabled {
      opacity: .4;
    }
  `}

  ${(p) => p.buttonType === IButtonTypeEnum.Outlined && css`
    border: 1px solid #E3E3E3;
    color: #04333B;
    font-weight: 400;
    display: flex;
    align-items: center;
    background-color: white;

    &:active {
      border: 1px solid #04333B;
    }

    &:disabled {
      opacity: .4;
    }
  `}

  ${(p) => p.buttonType === IButtonTypeEnum.Text && css`
    color: #04333B;
    font-weight: 600;
    font-size: 12px;
    text-decoration: underline;
    display: flex;
    align-items: center;
    padding: 0px;

    &:active {
      color: #1DBD6B;
    }

    &:hover {
      color: #1DBD6B;
    }

    &:disabled {
      color: #04333B;
      opacity: .4;
    }
  `}

  &:focus{
    outline: none;
  }


`;

export default ActionButton;
