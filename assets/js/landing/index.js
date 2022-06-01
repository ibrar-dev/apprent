import $ from 'jquery';
import axios from 'axios';
import 'jquery.easing';

$(document).ready(function () {
  "use strict"; // Start of use strict
  // Smooth scrolling using jQuery easing
  $('a.js-scroll-trigger[href*="#"]:not([href="#"])').click(function () {
    if (location.pathname.replace(/^\//, '') === this.pathname.replace(/^\//, '') && location.hostname === this.hostname) {
      let target = $(this.hash);
      target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
      if (target.length) {
        $('html, body').animate({
          scrollTop: (target.offset().top - 54)
        }, 1000, "easeInOutExpo");
        return false;
      }
    }
  });

  // Closes responsive menu when a scroll trigger link is clicked
  $('.js-scroll-trigger').click(function () {
    $('.navbar-collapse').collapse('hide');
  });

  // Activate scrollspy to add active class to navbar items on scroll
  $('body').scrollspy({
    target: '#mainNav',
    offset: 56
  });

  // Collapse Navbar
  const mainNav = $("#mainNav");
  const navbarCollapse = function () {
    if (mainNav.offset().top > 100) {
      mainNav.addClass("navbar-shrink");
    } else {
      mainNav.removeClass("navbar-shrink");
    }
  };
  // Collapse now if page is not at top
  navbarCollapse();
  // Collapse the navbar when page is scrolled
  $(window).scroll(navbarCollapse);
  $('#contact-form').submit((e) => {
    e.preventDefault();
    const formData = new FormData();
    let valid = true;
    $(e.target).find('input, textarea').each((i, f) => {
      const field = $(f);
      const name = field.attr('name');
      formData.append(name, field.val());
      const helpBlock = field.find('~ .help-block');
      if (field.val()) {
        helpBlock.text('');
      } else {
        valid = false;
        helpBlock.text('Please fill out this field');
      }
    });
    if (valid) {
      axios.post('/contact', formData).then(r => {
        $('#contact-success').find('.alert-success').show();
      }).catch(e => {
        $('#contact-success').find('.alert-danger').show();
      });
    }
  });
});


