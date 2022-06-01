import React from 'react';
import {englishTranslation} from '../../../components/localization';

import {
  Button,
  Modal,
  ModalBody,
  ModalFooter,
  ModalHeader,
} from 'reactstrap';

const displayAddressError = (error) => (
  Object.keys(error).map(key => displayError(key, englishTranslation[error[key]]))
)

const displayError = (errorKey, errorMessage) => (
  <div className="ml-3" key={errorKey}>
    <span style={{textTransform: "capitalize"}}>
      {englishTranslation[errorKey] || errorKey.replace(/_/g, " ")}:
    </span>
    <span className="ml-2 text-danger">{errorMessage}</span>
  </div>
)

const renderModelErrors = (section) => (
  section.errors && Object.keys(section.errors).map(errorKey => {
    const errorMessage = englishTranslation[section.errors[errorKey]];
    return displayError(errorKey, errorMessage)
  })
)

const renderCollectionErrors = (key, section) => (
  section.collectionErrors && section.collectionErrors.map((modelError, index) => {
    return (
      <div key={`modelError${index}`} className="ml-2">
        {key !== 'histories' && key !== 'employments' && `#${index + 1}`}
        {
          Object.keys(modelError).map(errorKey => {
            const error = section.collectionErrors[index][errorKey];
            if (typeof error === 'string') return displayError(errorKey, englishTranslation[error])
            return displayAddressError(error)
          })
        }
      </div>
    )
  })
)

const ProgressModal = ({onClose, application: {form_summary}}) => {
  const orderedSections = [
    "occupants",
    "move_in",
    "pets",
    "vehicles",
    "histories",
    "employments",
    "emergency_contacts",
    "documents"
  ];

  return (
    <Modal isOpen={true} toggle={onClose}>
      <ModalHeader toggle={onClose}>
        Application Progress
      </ModalHeader>
      <ModalBody>
        <ul className="list-unstyled">
          {
            orderedSections.map(key => {
              if (key === 'review') return null;
              const section = form_summary[key]
              const icon = section.done ? 'fa-check-circle text-success' : 'fa-times text-danger';
              return (
                <li key={key}>
                  <b style={{textTransform: "capitalize"}}>{key.replace("_", " ")}:</b>
                  <i className={`fas ${icon} ml-2`}/>
                  { renderModelErrors(section) }
                  { renderCollectionErrors(key, section) }
                </li>
              )
            })
          }
        </ul>
      </ModalBody>
    </Modal>
  )
}

export default ProgressModal;
