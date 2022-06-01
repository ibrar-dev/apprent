import React from "react";
import moment from "moment";
import Cell from "./itemCell";
import DateCell from "./dateCell";
import confirmation from "../../../components/confirmationModal";
import actions from "../actions";
import {Avatar} from "antd";

class Unit extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};

    this.completeCard = this.completeCard.bind(this);
    this.reverseCardCompletion = this.reverseCardCompletion.bind(this);
    this.moveInAndArchive = this.moveInAndArchive.bind(this);
    this.removeArchiveStatus = this.removeArchiveStatus.bind(this);
  }

  completeCard() {
    confirmation("Mark this card complete?").then(() => {
      const {card: {id}} = this.props;
      actions.updateCard({completion_status: "completed", id});
    });
  }

  reverseCardCompletion() {
    confirmation("Revert this card to incomplete?").then(() => {
      const {card: {id}} = this.props;
      actions.updateCard({completion_status: "incomplete", id});
    });
  }

  moveInAndArchive() {
    confirmation("Mark this as moved in? This will archive this card").then(() => {
      const {card: {id}} = this.props;
      actions.updateCard({hidden: true, id});
    });
  }

  removeArchiveStatus() {
    confirmation("Remove archive status from this card?").then(() => {
      const {card: {id}} = this.props;
      actions.updateCard({hidden: false, id});
    })
  }

  render() {
    const {card, cardType} = this.props;
    const itemKey = {};
    card.items.forEach((item) => { itemKey[item.name] = item; });
    const itemsComplete = card.items.every((i) => i.completed);
    return (
      <tr style={{background: card.completion ? "#b3f5c4" : "#fff"}}>
        <td className="nowrap text-center">
          <div className="d-flex align-items-center">
            <a href={`/units/${card.unit.id}`} target="_blank" rel="noreferrer">{card.unit.number}</a>
            <Avatar size={12} className="ml-1" src={card.property.icon} />
          </div>
        </td>
        <DateCell
          date={card.move_out_date}
          field="move_out_date"
          id={card.id}
          toolTipDisabled={cardType === 'hidden'}
        />
        <DateCell
          date={card.deadline}
          field="deadline"
          id={card.id}
          toolTipDisabled={cardType === 'hidden'}
        />
        <DateCell
          date={card.move_in_date}
          append={` (${moment(card.move_in_date).diff(moment(), "days")} days)`}
          field="move_in_date"
          id={card.id}
          toolTipDisabled={cardType === 'hidden'}
        />

        {
          !card.completion
          && (
            <>
              <Cell cardId={card.id} name="Power On" item={itemKey["Power On"]} />
              <Cell cardId={card.id} name="Trash Out" item={itemKey["Trash Out"]} />
              <Cell cardId={card.id} name="Paint" item={itemKey.Paint} />
              <Cell cardId={card.id} name="Clean" item={itemKey.Clean} />
              <Cell cardId={card.id} name="Carpet" item={itemKey.Carpet} />
              <Cell cardId={card.id} name="Punch" item={itemKey.Punch} />
              <Cell cardId={card.id} name="Countertops-Tubs" item={itemKey["Countertops-Tubs"]} />
              <Cell cardId={card.id} name="Pest Control" item={itemKey["Pest Control"]} />
              <Cell cardId={card.id} name="Keys Made" item={itemKey["Keys Made"]} />
              <Cell cardId={card.id} name="Final Inspection" item={itemKey["Final Inspection"]} />
            </>
          )
        }
        {
          card.hidden
          && (
            <td className="text-center" colSpan={10}>
              <a onClick={this.removeArchiveStatus} style={{textDecoration: "underline"}}>
                Remove Archive Status From This Card
              </a>
            </td>
          )
        }
        {
          card.completion
          && !card.hidden
          && (
            <td className="text-center" colSpan={10}>
              <a onClick={this.moveInAndArchive} style={{textDecoration: "underline"}}>
                Move In And Archive Card
              </a>
            </td>
          )
        }
        <td className="text-center">
          {
            itemsComplete
            && !card.completion
            && (
              <a onClick={this.completeCard}>
                <i className="fas fa-thumbs-up" />
              </a>
            )
          }
          {
            card.completion
            && !card.hidden
            && (
              <a onClick={this.reverseCardCompletion}>
                <i className="fas fa-check-circle" />
              </a>
            )
          }
        </td>
      </tr>
    );
  }
}

export default Unit;
