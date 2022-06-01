import React from "react";
import TabbedBox from './index';

const defaultHeaderStyle = {height: 60, border: '1px solid #e4e6eb', borderBottom: 'none', borderRight: 'none'};

class PropertiesTabbedBox extends React.Component {

  setProperty({data}) {
    this.props.setProperty(data);
  }

  render() {
    const {properties, property, title, standalone, headerStyle, headless} = this.props;
    const links = properties.map(p => {
      return {data: p, id: p.id, label: p.name, icon: p.icon}
    });
    if (standalone) delete defaultHeaderStyle.borderRight;
    return <TabbedBox links={links}
                      active={property.id}
                      header={!headless && <div className="d-flex card-header align-items-center rounded-0"
                                   style={{...defaultHeaderStyle, ...headerStyle}}>
                        {title}
                      </div>}
                      onNavigate={this.setProperty.bind(this)}>
      {React.Children.map(this.props.children, child => React.cloneElement(child, { property }))}
    </TabbedBox>;

  }
}

export default PropertiesTabbedBox;