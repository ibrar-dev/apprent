import CreditCard from './cc';
import BankAccount from './ba';
import 'bootstrap-switch';
import Profile from './profile';
import Social from './social';
import './payments';
import './rewards';

import Channel from './rewardsChannel';

window.$ = $;
window.ModalMessage = (title, message, cancel = false) => {
  const modal = $('#app-modal');
  $('#modal-message').text(message);
  $('#modal-title').text(title);
  const cancelBtn = $('#modal-cancel');
  cancel ? cancelBtn.show() : cancelBtn.hide();
  modal.modal();
  return new Promise((resolve, reject) => {
    cancelBtn.click(reject);
    $('#modal-accept').click(resolve);
  });
};

$.extend($.easing, {
  easeOutSine: function easeOutSine(x, t, b, c, d) {
    return c * Math.sin(t / d * (Math.PI / 2)) + b;
  }
});

$(document).ready(function () {
  const channel = new Channel();
  $('#search_rewards').on('input', function ({target: {value}}) {
    if (value != '') {
      value != "" && channel.socket.channels[0].push("SEARCH_REWARDS", value)
    }
  })
});

$(document).ready(function () {
  const slideConfig = {
    duration: 270,
    easing: 'easeOutSine'
  };
  $(':not(.main-sidebar--icons-only) .dropdown').on('show.bs.dropdown', function () {
    $(this).find('.dropdown-menu').first().stop(true, true).slideDown(slideConfig);
  }).on('hide.bs.dropdown', function () {
    $(this).find('.dropdown-menu').first().stop(true, true).slideUp(slideConfig);
  });
  $('#submit-cc').click(CreditCard.submit);
  $('#submit-ba').click(BankAccount.submit);
  $('#number').keyup(CreditCard.setCardType);
  $('[data-toggle="popover"]').popover();

  $('.acc-switch').on('click', (event) => {
    if (event.target.id == 'mailings-switch') {
      if (!event.target.checked) alert('Note: By Opting out of emails you may not receive important correspondence as email is our primary method of communication.');
      Profile.updateProfile({receives_mailings: event.currentTarget.checked});
    }
  });
});


$(document).ready(function () {
  $('#timeLine').on('click', 'i.fa-heart', function () {
    if (this.id === "") {
      Social.likeComment({post_id: this.params[0], tenant_id: this.params[1], like_id: ""});
      this.parentNode.childNodes[3].innerHTML = parseInt(this.parentNode.childNodes[3].innerHTML) + 1;
      this.setAttribute("id", "liked");
    } else {
      Social.likeComment({post_id: this.params[0], tenant_id: this.params[1], like_id: this.id});
      this.parentNode.childNodes[3].innerHTML = parseInt(this.parentNode.childNodes[3].innerHTML) - 1;
      this.setAttribute("id", "");
    }
  });

  const body = $('body');

  body.on('click', 'li.block', function () {
    if (confirm("Are you sure you want to block this user? You will no longer be able to see or interact with their posts.")) {
      Social.blockUser({blockee_id: this.id, tenant_id: this.value});
    }
  });

  $('#reportModal').on('show.bs.modal', function (event) {
    $(this).find("#reportButton")[0].setAttribute("reportee", $(event.relatedTarget)[0].getAttribute("data-reportee"));
    $(this).find("#reportButton")[0].setAttribute("post", $(event.relatedTarget)[0].getAttribute("data-post"));
  });

  body.on('click', 'button.report', function () {
    Social.reportPost({
      tenant_id: this.getAttribute("reportee"),
      post_id: this.getAttribute("post"),
      reason: this.getAttribute("reason")
    });
    document.getElementById('reportModal').childNodes[1].childNodes[1].childNodes[1].innerHTML = "Thank you, we will review this post and take the appropriate actions."
    document.getElementById('reportModal').childNodes[1].childNodes[1].childNodes[3].childNodes[3].style.display = "none";
  });

  body.on('click', 'li.delete', function () {
    if (confirm("Are you sure you want to permanently remove this post?")) {
      Social.deletePost({post_id: parseInt(this.id)});
      document.getElementById(this.getAttribute("data-post")).style.display = "none";
    }
  });
});
