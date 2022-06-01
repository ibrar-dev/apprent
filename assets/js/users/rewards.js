import axios from 'axios';

$(document).ready(() => {
  $('.reward-btn').click((e) => {
    const cart = JSON.parse(localStorage.getItem('cart'));
    if(cart.length != 0) {
      const button = $(e.target).closest('button');
      const modalAppend = $('#modal-append');
      const prize_ids = cart.map(x => x.id);
      modalAppend.append(button.children('span').clone());
      ModalMessage('Redeem Reward', 'Please allow 1 - 2 business days to process your order', true).then(() => {
        axios.post('/rewards', {reward_ids: prize_ids}).then(() => {
          setTimeout(() => {
            localStorage.setItem('cart', JSON.stringify([]))
            ModalMessage('Success', 'Your purchase was successful').then(() => {
              setTimeout(() => {
                location.reload()
              }, 300);
            });
          }, 700);
        }).catch(e => {
          setTimeout(() => {
            ModalMessage('Error', e.response.data.error).then(() => {
            });
          }, 700);
        });
        modalAppend.empty();
      }).catch(() => {
        modalAppend.empty();
      });
    } else {
      alert("Cart is empty")
    }
  });
});
