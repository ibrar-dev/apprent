import React from 'react';
import ReactDom from 'react-dom';
import {connect, Provider} from 'react-redux'
import {createStore} from 'redux';
import Lottie from 'lottie-web';
import * as animationData from '../../../static/animations/apprent_logo_animation.json';
import * as coolAnimationData from '../../../static/animations/coolAnimatedApprentLogo';

const reducer = (state = false, isLoading) => isLoading;
const store = createStore(reducer);
const setLoading = isLoading => store.dispatch({type: 'SET_LOADING', isLoading});

const defaultOptions = {
  loop: true,
  autoplay: true,
  animationData: coolAnimationData.default,
  rendererSettings: {
    preserveAspectRatio: 'xMidYMid slice'
  },
  speed: 2
};

class Loading extends React.Component {
  constructor(props) {
    super(props);
    this.ref = React.createRef();
  }

  componentDidMount() {
    this.anim = Lottie.loadAnimation({...defaultOptions, container: this.ref.current});
  }

  render() {
    const {isLoading} = this.props;
    if (this.anim) (isLoading ? this.anim.play() : this.anim.stop());
    return <div id="loader" className={isLoading ? 'd-flex' : 'd-none'}>
      <div ref={this.ref}/>
    </div>
  }
}

const Wrapped = connect(state => state)(Loading);

ReactDom.render(<Provider store={store}><Wrapped/></Provider>, document.getElementById('loading-container'));

export default setLoading;