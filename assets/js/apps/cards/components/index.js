import React, {Component} from "react";
import {Button, Space, Radio} from "antd";
import {connect} from "react-redux";
import moment from "moment";
import {CSVLink} from "react-csv";
import Unit from "./unit";
import AddUnitModal from "./addUnitModal";
import Pagination from "../../../components/pagination";
import MultiPropertySelect from "../../../components/multiPropertySelect";
import actions from "../actions";
import renderers from "../helpers/renderers";
import PdfExport from "../../../components/pdf";

const itemValue = (item) => {
  if (!item) return "9999-99-99";
  if (item.completed) return "0000-00-00";
  return item.scheduled;
};

const itemSort = (itemName) => (card1, card2) => {
  const item1 = card1.items.find((i) => i.name === itemName);
  const item2 = card2.items.find((i) => i.name === itemName);
  return itemValue(item1) > itemValue(item2) ? 1 : -1;
};

const headers = [
  {label: "Unit", sort: (i1, i2) => (i1.unit.number > i2.unit.number ? 1 : -1)},
  {label: "Move Out Date", sort: "move_out_date"},
  {label: "Ready Date", sort: "deadline"},
  {label: "Move In", sort: "move_in_date"},
  {label: "Power On", sort: itemSort("Power On")},
  {label: "Trash Out", sort: itemSort("Trash Out")},
  {label: "Paint", sort: itemSort("Paint")},
  {label: "Clean", sort: itemSort("Clean")},
  {label: "Carpet", sort: itemSort("Carpet")},
  {label: "Punch", sort: itemSort("Punch")},
  {label: "Countertops/Tubs", sort: itemSort("Countertops-Tubs")},
  {label: "Pest Control", sort: itemSort("Pest Control")},
  {label: "Keys Made", sort: itemSort("Keys Made")},
  {label: "Maintenance Sign Off", sort: itemSort("Final Inspection")},
  {label: "Office Sign Off"},
];

const headerLabels = headers.map((h) => h.label);

const exportData = (cards) => (
  cards.map((card) => ([
    renderers.unitNumber(card),
    renderers.moveOutDate(card),
    renderers.readyDate(card),
    renderers.moveInDate(card),
    renderers.item(card.items, "Power On"),
    renderers.item(card.items, "Trash Out"),
    renderers.item(card.items, "Paint"),
    renderers.item(card.items, "Clean"),
    renderers.item(card.items, "Carpet"),
    renderers.item(card.items, "Punch"),
    renderers.item(card.items, "Countertops/Tubs"),
    renderers.item(card.items, "Pest Control"),
    renderers.item(card.items, "Keys Made"),
    renderers.item(card.items, "Maintenance Sign Off"),
    renderers.complete(card),
  ]))
);

class Cards extends Component {
  constructor(props) {
    super(props);
    this.state = {
      cardType: "active",
      activeCardType: "all",
      addUnitModal: false,
    }
    this.addUnit = this.addUnit.bind(this);
    this.displayCards = this.displayCards.bind(this);
    this.handleActiveCardTypeChange = this.handleActiveCardTypeChange.bind(this);
    this.handleCardTypeChange = this.handleCardTypeChange.bind(this);
  }
  
  handleCardTypeChange = e => {
    this.setState({ cardType: e.target.value });
  };
  
  handleActiveCardTypeChange = (type) => {
    this.setState({activeCardType: type})
    const cardIds = this.displayActiveCards(type).map(c => c.id)
    actions.fetchCardEvents(cardIds)
  }

  addUnit() {
    const {addUnitModal} = this.state;
    this.setState({addUnitModal: !addUnitModal});
  }

  formatEventName(name) {
    return (
      name.split("_")
        .map((x) => x.charAt(0).toUpperCase() + x.slice(1))
        .join(" ")
    );
  }

  renderDomainEvent() {
    const {domainEvent} = this.props;
    const {subject_id, name, inserted_at, property_name, unit_number, admin_name} = domainEvent;
    if (!subject_id) return null;
    const event = new Date(inserted_at + "Z");
    const options = { weekday: 'short', month: 'short', day: 'numeric', hour: "2-digit", minute: "2-digit", timeZoneName: "short" };
    
    return (
      <div key={subject_id}>
        <b>Last Updated on {event.toLocaleDateString(undefined, options)}:</b>
        {" "}
        {this.formatEventName(name)}
        {" "}
        -
        {" "}
        {property_name}
        {" "}
        {unit_number}
        {" "}
        -
        {" "}
        {admin_name}
      </div>
    );
  }

  groupByOccupied = (cards) => {
    const occupied = [];
    const notOccupied = [];

    cards.map((c) => (
      c.move_out_date && moment(c.move_out_date) > moment() ? occupied.push(c) : notOccupied.push(c)
    ));

    return {occupied, notOccupied}
  };

  groupVacantByReady = (notOccupiedCards) => {
    const vacantReady = [];
    const vacantNotReady = [];
    notOccupiedCards.filter((c) => c.completion !== null ? vacantReady.push(c) : vacantNotReady.push(c));
    return {vacantReady, vacantNotReady}
  }

  activeCardTypes = () => {
    const {cards, archived} = this.props;
    const sorted = cards.sort((a, b) => a.unit.number > b.unit.number);
    // Occupied units have a move-out date in the future
    const { occupied, notOccupied } = this.groupByOccupied(sorted);
    const {vacantReady, vacantNotReady} = this.groupVacantByReady(notOccupied);
    const totalVacant = vacantReady.concat(vacantNotReady).sort((a,b) => a.unit.number > b.unit.number);

    return {
      allCards: sorted,
      occupied,
      vacantReady,
      vacantNotReady,
      archived,
      totalVacant,
    }
  }

  displayCards = () => {
    const {cardType, activeCardType} = this.state;
    const {hiddenCards} = this.props;
    const sortedHidden = hiddenCards.sort((a,b) => a.unit.number > b.unit.number);
    return cardType === "active" ? this.displayActiveCards(activeCardType) : sortedHidden;
  };

  displayActiveCards = (type) => {
    const {occupied, vacantReady, vacantNotReady, totalVacant, allCards} = this.activeCardTypes()
    switch(type) {
      case "all":
        return allCards
      case "occupied":
        return occupied;
      case "vacant":
        return totalVacant;
      case "vacantReady":
        return vacantReady;
      case "vacantNotReady":
        return vacantNotReady;
        // no default
    } 
  };

  render() {
    const {addUnitModal, cardType, activeCardType} = this.state;
    const {cards, units} = this.props;
    const cardedUnitIds = cards.map((c) => c.unit.id);
    const{occupied, vacantReady, vacantNotReady, totalVacant, allCards} = this.activeCardTypes();
    const displayCards = this.displayCards();

    return (
      <>
        <Pagination
          title={(
            <div className="w-100 flex-column">
              <MultiPropertySelect
                selectProps={{bordered: true}}
                className="flex-fill"
                onChange={actions.selectProperties}
              />
              <div className="mt-1 mb-0 d-flex justify-content-start" style={{minHeight: "32px"}}>
                {
                  cardType === "active"
                    ? (
                      <>
                        <Button
                          type={activeCardType === "all" ? "text" : "link"}
                          className="mr-4"
                          onClick={() => this.handleActiveCardTypeChange("all")}
                        >
                          <b>{allCards.length}</b>
                          {" "}
                          Total Units
                        </Button>
                        <Button
                          type={activeCardType === "occupied" ? "text" : "link"}
                          className="mr-4" 
                          onClick={() => this.handleActiveCardTypeChange("occupied")}
                        >
                          <b>{occupied.length}</b>
                          {" "}
                          Occupied Units
                        </Button>
                        <Button
                          type={activeCardType === "vacant" ? "text" : "link"}
                          className="mr-4"
                          onClick={() => this.handleActiveCardTypeChange("vacant")}
                        >
                          <b>{totalVacant.length}</b>
                          {" "}
                          Total Vacant
                        </Button>
                        <Button
                          type={activeCardType === "vacantNotReady" ? "text" : "link"}
                          className="mr-4"
                          onClick={() => this.handleActiveCardTypeChange("vacantNotReady")}
                        >
                          <b>{vacantNotReady.length}</b>
                          {" "}
                          Vacant Not Ready Units
                        </Button>
                        <Button
                          type={activeCardType === "vacantReady" ? "text" : "link"}
                          className="mr-4"
                          onClick={() => this.handleActiveCardTypeChange("vacantReady")}
                        >
                          <b>{vacantReady.length}</b>
                          {" "}
                          Vacant Ready Units
                        </Button>
                      </>
                    )
                  : null
                }
              </div>
              <div className="my-3" style={{minHeight: "32px"}}>
                {cardType === "active" ? this.renderDomainEvent() : null}
              </div>
            </div>
          )}
          collection={displayCards}
          component={Unit}
          additionalProps={{cardType}}
          tableClasses="data-table"
          headers={headers}
          field="card"
          filters={(
            <Space>
              <Radio.Group value={cardType} onChange={this.handleCardTypeChange}>
                <Radio.Button value="active">Active</Radio.Button>
                <Radio.Button value="hidden">Archived</Radio.Button>
              </Radio.Group>
              <CSVLink
                data={[headerLabels].concat(exportData(displayCards))}
                filename={`MakeReady_${moment().format("MMDDYY")}.csv`}
              >
                <Button shape="circle" icon={<i className="fas fa-file-csv" />} />
              </CSVLink>
              <PdfExport
                columns={headerLabels}
                rows={exportData(displayCards)}
                fileName={`MakeReady_${moment().format("MMDDYY")}.pdf`}
              />
              <Button
                className="ml-2"
                color="success"
                onClick={this.addUnit}
              >
                Add Unit
              </Button>
            </Space>
          )}
          className="h-100 border-left-0 rounded-0"
          hidePerPage
        />
        {
          addUnitModal && (
            <AddUnitModal
              units={units.filter((u) => !cardedUnitIds.includes(u.id))}
              toggle={this.addUnit}
            />
          )
        }
      </>
    );
  }
}

export default connect(({
  cards, units, selectedProperties, domainEvent, hiddenCards,
}) => ({
  cards, units, selectedProperties, domainEvent, hiddenCards,
}))(Cards);
