import React from "react";
import icons from '../flatIcons';

const spanishTranslation = {
    flag: icons.spain,
    language: 'Espanol',
    success: 'Success',
    account: 'Cuenta',
    phoneNumber: 'Número de teléfono',
    password: 'Contraseña',
    confirmPassword: 'Confirmat Contraseña',
    dashboard: 'Tablero',
    welcome: 'Bienvenidos',
    category: 'Categoría',
    subCategory: 'Subcategoría',
    notes: 'Notas',
    entryAllowed: 'Acceso permitido',
    complete: 'Completo',
    notifyTenant: 'Notificar al Residente',
    open: 'Abrir',
    accept: 'Aceptar',
    decline: 'Declinar',
    noPending: 'No tiene órdenes de trabajo asignadas, comuníquese con su gerente para asignar las órdenes de trabajo.',
    order: 'Orden',
    details: 'Detalles',
    materials: 'Materiales',
    pause: 'Pausa',
    presshold: 'Manténgalo presionado para cerrar la sesión.',
    clickscan: 'Haga clic para escanear',
    withdrawreason: 'Motivo de retiro',
    completenotes: 'Notas de finalización de la orden de trabajo',
    youhave: 'Tienes',
    assignments: 'Asignaciones',
    signout: 'Desconectar',
    completethisorder: 'Completa esta orden',
    mysettings: 'Mi configuración',
    languageChanged: 'Idioma actualizado',
    noteSaved: 'Nota guardada',
    myToolbox: "Mi Caja de Herramientas",
    successAdd: "sus artículos se han añadido con éxito a su caja de herramientas. Tenga en cuenta que si está dispuesto a devolver cualquier cosa, debe traerlo de vuelta a esta tienda.",
    confirmItems: "Por favor, confirme que estos son los únicos artículos que está sacando de la tienda",
    thankYou: 'Gracias',
    cancel: 'cancelar',
    confirm: "Confirmar",
    confirmCheckOut: "Confirmar compra",
    processedCheckOut: "Felicitaciones, pago procesado!",
    shopItems: 'Artículos de la Tienda',
    signedOut: 'será cerrado la sesión',
    youHave: 'Tienes',
    itemsIn: 'elementos en su',
    cart: "carro",
    toolbox: 'caja de instrumento',
    checkOut: 'Compra',
    return: 'Devolver',
    available: 'Disponible',
    name: 'Nombre',
    //RENTALAPPLICATION FORM below
    occupants: 'Ocupantes',
    status: 'Estado',
    full_name: 'Nombre Completo',
    email: 'Email',
    dob: 'Fecha de nacimiento',
    ssn: 'Número de seguridad social',
    home_phone: 'Teléfono de casa',
    work_phone: 'Teléfono del trabajo',
    cell_phone: 'Teléfono móvil',
    drivers_license: 'Licencia de Conducir',
    number: 'Numero',
    state: 'Estado',
        //Move in Info
    mii: 'Mover en la Información',
    emi: 'Movimiento Esperado En',
    unit_number: 'Unidad Numérica',
        //Pets
    add_pet: 'Añadir Mascota',
    pet: 'Mascota',
    type: 'Tipo',
    breed: 'La Variedad',
    weight: 'Peso',
        //Vehicles
    vehicle: 'Vehículo',
    model: 'Haz un modelo',
    color: 'Color',
    license: 'Placa',
    add_vehicle: 'Añadir vehículo',
        //Previous Residences
    prev_residences: 'Residencias Anterior',
    address: 'Dirección',
    duration_residency: 'Duración de la residencia',
    rent: 'Alquilas en este lugar',
    rental_amount: 'Monto del alquiler',
    landlord_name: 'Nombre del propietario',
    landlord_num: 'Número de propietario',
    landlord_email: 'Email del propietario',
        //Employment Info
    employment_info: 'Informacion de Empleo',
    employer: 'Empleador',
    occupant: 'Ocupante',
    supervisor_name: 'Nombre del Supervisor',
    employment_duration: 'Duración de Empleo',
    salary: 'Salario Mensual',
    other_income: 'Otros Ingresos',
    description: 'Descripción',
    monthly_income: 'Ingreso Mensual',
        //Emergency Contacts
    add_contact: 'Agregar Contacto',
    contact: 'Contacto',
    relationship: 'Relación',
        //Documents
    add_document: 'Añadir Documento',
    required_document: "Su talón de pago y licencia de conducir o cualquier otra identificación emitida por un Estado son requeridas como parte del proceso de aplicación.",
    document: 'Documento',
    file: 'Expediente',
    pay_stub: 'Talón de Pago',
    choose_file: 'Elija el Archivo',
    pets_vehicles: 'Mascotas y Vehículos',
    continue_saved: 'Continuar la Aplicación Guardada',
    prev: 'Previo',
    save: 'Guardar',
    next: 'Próximo',
        //labels
    move_in: 'Mover en la Información',
    pets: 'Mascotas',
    vehicles: 'Vehículos',
    histories: 'Residencias Previa',
    employments: 'Informacion de Empleo',
    income: '',
    emergency_contacts: 'Contactos de Emergencia',
    documents: 'Subir Documentos',
    review: 'Revisión',
        //ERRORS
    description_error: 'Introducir descripción',
            //person.js
    name_error: 'Ingrese su Nombre',
    ssn_error: 'SSN inválido (ingrese solo 9 dígitos)',
    email_error: 'Ingrese un email valido',
    phone_error: 'Introduzca al menos un número de teléfono',
    invalid_dob: 'La fecha de nacimiento es inválida',
    too_young: 'El arrendatario debe ser mayor de 18 años',
    license_error: 'Ingrese el número de licencia de conducir',
    license_state_error: 'Seleccione el estado de la licencia de conducir',
    status_error: 'Seleccionar estado de ocupante',
            //movein.js
    movein_error: 'Introduzca fecha de mudanza',
            //address.js
    invalid_address: 'Dirección inválida',
    address_error: 'Ingresa la direccion',
    city_error: 'Entrar en ciudad',
    state_error: 'Entrar en estado',
    zip_error: 'Ingresa tu código postal',
            //histories.js
    ll_name_error: 'Ingrese el nombre del propietario',
    ll_num_error: 'Ingrese el número de teléfono del propietario',
    rent_error: 'Ingrese el monto del alquiler',
    residency_duration_error: 'Introduzca la duración de la residencia',
    current_error: 'Entrar actual',
            //employment.js
    choose_occupant: 'Elegir Ocupante',
    employment_duration_error: 'Introduzca la duración del empleo',
    employment_name_error: 'Ingrese el nombre del empleador',
    employment_num_error: 'Ingrese el número de teléfono del empleador',
    employment_email_error: 'Ingrese el email del supervisor',
    employment_super_error: 'Ingrese el nombre del supervisor',
    salary_error: 'Introducir salario',
            //pet.js
    pet_name_error: 'Ingrese el nombre de la mascota',
    pet_breed_error: 'Ingrese la raza de mascota',
    pet_type_error: 'Ingrese el tipo de mascota',
    pet_weight_error: 'Introduzca el peso de la mascota',
            //vehicle.js
    vehicle_mm_error: 'Ingresar marca / modelo de vehículo',
    vehicle_color_error: 'Introduce el color del vehículo',
    vehicle_license_error: 'Ingrese el número de placa',
    vehicle_license_state_error: 'Ingrese el estado de la placa',
            //contact.js
    contact_name_error: 'Ingrese el nombre del contacto',
    contact_phone_error: 'Entrar en el teléfono de contacto',
    contact_phone_same_as_occupant: 'Ingrese un número de teléfono que sea único de los solicitantes',
    contact_relation_error: 'Entrar en contacto de relacion',
            //document.js
    document_type_error: 'Ingrese el tipo de documento',
            //Review & Pay & Terms
    submit_app_button: 'Enviar Mi Solicitud',
    submit_fix_errors_button: 'Por Favor Corrija Errores',
    accept_t_and_c_header: 'Por Favor Acepte Los Términos Y Condiciones',
    name_and_agree_input: 'aceptar los términos y condiciones mencionados anteriormente',
    fee_refundability: "Las tarifas pagadas no son reembolsables.",
    fee_information: "Pagar la Tarifa de Administración ahora? Aplicaciones completas (las que son presentadas con el pago de la tarifa de aplicación y la tarifa de administración) van a ser procesadas por nuestro personal inmediatamente, resultando en una la fecha más temprana de mudanza para las aplicaciones aceptadas. Todos los otros aplicantes serán procesados en el orden recibido, lo cual puede causar retrasos si alguna información está incompleta.",
    pay_admin_fee_now: "¿Pagar la tarifa administrativa ahora?",
    i: 'Yo',
    yes: 'Si'
};

export const englishTranslation = {
    flag: icons.united_states,
    language: 'English',
    success: 'Success',
    account: 'Account',
    phoneNumber: 'Phone Number',
    password: 'Password',
    confirmPassword: 'Confirm Password',
    dashboard: 'Dashboard',
    welcome: 'Welcome',
    category: 'Category',
    subCategory: 'Sub Cat',
    notes: 'Notes',
    entryAllowed: 'Entry Allowed',
    complete: 'Complete',
    notifyTenant: 'Notify Resident',
    open: 'Open',
    accept: 'Accept',
    decline: 'Withdraw',
    noPending: 'There are no work orders assigned to you. \nPlease contact your manager to assign work orders.',
    order: 'Order',
    details: 'Details',
    materials: 'Materials',
    pause: 'Pause',
    presshold: 'Press and Hold To Logout.',
    clickscan: 'Click to Scan',
    withdrawreason: 'Reason For Withdrawal',
    completenotes: 'Work Order Completion Notes',
    youhave: 'You Have',
    assignments: 'Assignments',
    signout: 'Sign Out',
    completethisorder: 'Complete this Order',
    mysettings: 'My Settings',
    createNote: 'Create Note',
    noteText: 'Enter your note',
    snapPhoto: 'Take Photo',
    cancelPhoto: 'Cancel Photo',
    languageChanged: 'Language Changed',
    noteSaved: "Note Saved",
    myToolbox: "My ToolBox",
    addSuccess: "your items have been succesfully added to your toolbox. Please note that if you're inclined to return anything you must bring it back to this shop.",
    confirmItems: 'Please confirm these are the only items you are taking from the shop',
    thankYou: 'Thank You!',
    cancel: 'Cancel',
    confirm: 'Confirm',
    confirmCheckOut: "Confirm Checkout",
    processedCheckOut: "Congratulations, checkout processed!",
    shopItems: 'Shop Items',
    signedOut: 'you will be signed out in',
    youHave: 'You have',
    itemsIn: 'items in your',
    cart: 'cart',
    toolbox: 'toolbox',
    checkOut: 'Checkout',
    return: 'Return',
    available: 'Available',
    name: 'Name',
    //RENTALAPPLICATION FORM below
    occupants: 'Occupants',
    status: 'Status',
    full_name: 'Full Name',
    email: 'Email',
    dob: 'Date of Birth',
    ssn: 'Social Security Number',
    home_phone: 'Home Phone',
    work_phone: 'Work Phone',
    cell_phone: 'Cell Phone',
    drivers_license: 'Drivers License',
    dl_number: 'Drivers License #',
    number: 'Number',
    state: 'State',
        //Move in Info
    mii: 'Move In Information',
    emi: 'Expected Move In',
    unit_number: 'Unit Number',
        //Pets
    add_pet: 'Add Pet',
    pet: 'Pet',
    type: 'Type',
    breed: 'Breed',
    weight: 'Weight',
        //Vehicles
    vehicle: 'Vehicle',
    model: 'Make/Model',
    color: 'Color',
    license: 'License Plate',
    add_vehicle: 'Add Vehicle',
        //Previous Residences
    prev_residences: 'Previous Residency',
    address: 'Address',
    duration_residency: 'Duration of Residency',
    rent: 'Do you rent at this location',
    rental_amount: 'Amount of Rent',
    landlord_name: 'Landlord  Name',
    landlord_num: 'Landlord Number',
    landlord_email: 'Landlord Email',
        //Employment Info
    employment_info: 'Employment Information',
    employer: 'Employer',
    occupant: 'Occupant',
    supervisor_name: 'Supervisor Name',
    employment_duration: 'Duration of Employment',
    salary: 'Monthly Salary',
    other_income: 'Other Income',
    description: 'Description',
    monthly_income: 'Monthly Income',
        //Emergency Contacts
    add_contact: 'Add Contact',
    contact: 'Contact',
    relationship: 'Relationship',
        //Documents
    add_document: 'Add Document',
    required_document: "Your pay-stub(s) and driver's license or other form of state-issued ID are required as part of the application process.",
    document: 'Document',
    file: 'File',
    pay_stub: 'Pay Stub',
    choose_file: 'Choose File',
    pets_vehicles: 'Pets and Vehicles',
    continue_saved: 'Continue Saved Application',
    prev: 'Previous',
    save: 'Save',
    next: 'Next',
        //labels
    move_in: 'Move In Information',
    pets: 'Pets',
    vehicles: 'Vehicles',
    histories: 'Previous Residency',
    employments: 'Employment Information',
    income: 'Income',
    emergency_contacts: 'Emergency Contacts',
    documents: 'Upload Documents',
    review: 'Review',
        //ERRORS
    description_error: 'Enter Description',
            //person.js
    name_error: 'Enter Name',
    ssn_error: 'Invalid SSN (enter 9 digits only)',
    email_error: 'Enter valid email',
    phone_error: 'Enter at least one phone number',
    invalid_dob: 'Date of birth is invalid',
    too_young: 'Lease Holder must be over 18',
    license_error: 'Enter drivers license number',
    license_state_error: 'Select drivers license state',
    status_error: 'Select Occupant Status',
            //movein.js
    movein_error: 'Enter move in date',
            //address.js
    invalid_address: 'Invalid Address',
    address_error: 'Enter address',
    city_error: 'Enter city',
    state_error: 'Enter state',
    zip_error: 'Enter Zip Code',
            //histories.js
    ll_name_error: 'Enter Landlord Name',
    ll_num_error: 'Enter Landlord Phone Number',
    rent_error: 'Enter rent amount',
    residency_duration_error: 'Enter duration of residency',
    current_error: 'Enter Current',
            //employment.js
    choose_occupant: 'Choose Occupant',
    employment_duration_error: 'Enter employment duration',
    employment_name_error: 'Enter employer name',
    employment_num_error: 'Enter employer phone number',
    employment_email_error: 'Enter supervisor email',
    employment_super_error: 'Enter supervisor name',
    salary_error: 'Enter salary',
            //pet.js
    pet_name_error: 'Enter pet name',
    pet_breed_error: 'Enter pet breed',
    pet_type_error: 'Enter pet type',
    pet_weight_error: 'Enter pet weight',
            //vehicle.js
    vehicle_mm_error: 'Enter vehicle make/model',
    vehicle_color_error: 'Enter vehicle color',
    vehicle_license_error: 'Enter license plate number',
    vehicle_license_state_error: 'Enter license plate state',
            //contact.js
    contact_name_error: 'Enter contact name',
    contact_phone_error: 'Enter contact phone',
    contact_phone_same_as_occupant: 'Enter a phone number that is unique from the applicants',
    contact_relation_error: 'Enter contact relationship',
            //doocument.js
    document_type_error: 'Enter document type',
            //Review & Pay & Terms
    submit_app_button: 'Submit My Application',
    submit_fix_errors_button: 'Please correct errors',
    accept_t_and_c_header: 'Please Accept the Terms and Conditions',
    name_and_agree_input: 'agree to the terms and conditions listed above',
    fee_refundability: "Fees paid are non-refundable.",
    fee_information: "Complete applications (those submitted with payment of both the Application Fee and Administrative Fee) will be processed by our staff immediately upon receipt, resulting in the soonest possible move-in date for accepted applicants. All other applications will be processed in the order received, which may result in delays if information or documentation is missing.",
    pay_admin_fee_now: "Pay Admin Fee now?",
    i: 'I',
    yes: 'Yes',
};

const localization = (language) => {
  if(language === "es_419") {
    return spanishTranslation;
  } else {
    return englishTranslation;
  }
}

export default localization;