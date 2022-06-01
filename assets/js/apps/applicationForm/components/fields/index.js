import addressFields from './address';
import boolean from './bool';
import date from './date';
import file from './file';
import list from './list';
import phone from './phone';
import ssn from './ssn';
import select from './select';
import state from './state';
import text from './text';
import ccNum from './ccNum';
import expDate from './expDate';
import full_name from './name';

const address = window.APPLICATION_JSON ? text : addressFields;
export default {full_name, address, boolean, date, file, list, phone, select, state, text, ssn, ccNum, expDate, number: text, password: text};