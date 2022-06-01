import React from "react";
import styled from "styled-components";
import ActionButton from "../../actionButton";
import {IButtonTypeEnum} from "../../utils/enums";

const ListHeader = ({count, onClear, onSelectAll}) => (
  <Wrapper>
    <div>
      {`${count || 0} Selected`}
    </div>
    <ActionButton
      onClick={count && count > 0 ? onClear : onSelectAll}
      type={IButtonTypeEnum.Text}
      title={count && count > 0 ? "Clear" : "Select All"}
    />
  </Wrapper>
);

const Wrapper = styled.div`
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: space-between;

  padding-left: 12px;
  padding-right: 12px;

  border: 1px solid #E3E3E3;
  border-radius: 8px 8px 0px 0px;

  border-bottom-width: 0px;
`;

export default ListHeader;
