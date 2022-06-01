import moment from 'moment';

const formattedDuration = (input) => {
  if (input) {
    const completion_time = input
    const dur = moment.duration(completion_time, "seconds").humanize()
    return dur
  } else {
    return "N/A"
  }
}

export default formattedDuration;
