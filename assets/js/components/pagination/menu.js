import React from 'react';
import {Popover, PopoverBody, Button,} from 'reactstrap';

class Menu extends React.Component {
  state = {open: false};

  toggle() {
    this.setState({open: !this.state.open});
  }

  closeMenu() {
    this.setState({open: false});
  }

  openMenu() {
    this.setState({open: true});
    document.addEventListener('click', this.closeMenu.bind(this), {once: true});
  }

  render() {
    const {items} = this.props;
    const {open} = this.state;
    return <>
      <Button id="pagination-menu"
              className="mt-0 pb-1"
              onClick={this.openMenu.bind(this)}
              style={{backgroundColor: open ? '#bcc6d0' : 'transparent', color: "#000", border: "none"}}>
        <i className="fas fa-ellipsis-v font-sze"/>
      </Button>
      <Popover placement="bottom" isOpen={open} target="pagination-menu" className="popover-max"
               toggle={this.toggle.bind(this)}
               onClick={this.toggle.bind(this)}>

        <PopoverBody className="d-flex flex-column pb-0">
          {items.map((i, index) => {
            if (i.render) return i.render(i.id, index)
            return (
              <Button
                key={index}
                id={i.id}
                color='info'
                outline
                onClick={i.onClick}
                className="mt-0 btn-spacing"
              >
                {i.title}
              </Button>)
            })}
        </PopoverBody>
      </Popover>
    </>;
  }
}

export default Menu;