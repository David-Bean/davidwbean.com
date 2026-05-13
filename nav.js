(function () {
  var btn = document.getElementById('nav-hamburger');
  var nav = btn && btn.closest('nav');
  if (!btn || !nav) return;

  btn.addEventListener('click', function () {
    var open = nav.classList.toggle('open');
    btn.setAttribute('aria-expanded', open);
  });

  document.addEventListener('click', function (e) {
    if (!nav.contains(e.target)) {
      nav.classList.remove('open');
      btn.setAttribute('aria-expanded', 'false');
    }
  });
})();
