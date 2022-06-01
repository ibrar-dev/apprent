class FileExport extends Component {
  constructor() {
    super(props)
    this.state = {modal: false};
  }

  pdfDownload() {
    this.props.pdf.save(date);
  }

  render() {
    const {toggle, modal, pdf, csv} = this.props;
    return <Modal isOpen={modal} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>Export Options</ModalHeader>
      <ModalBody style={{height: "600px"}}>
      <iframe type="application/pdf" src={pdf.output('datauristring')} height="100%" width="100%"/>
      </ModalBody>
      <ModalFooter>
        {/*<Button color="primary" onClick={this.pdfDownload.bind(this)}>E-Mail</Button>*/}
        <CSVLink data={csv} filename={date}><Button color="primary">CSV Download</Button></CSVLink>
        <Button color="primary" onClick={this.pdfDownload.bind(this)}>PDF Download</Button>
        <Button color="secondary" onClick={toggle}>Close</Button>
      </ModalFooter>
    </Modal>
  }
}

export default FileExport
