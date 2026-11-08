// Use a dark theme if the browser prefers one, unless the theme was switched
// with the toggle button. The choice is stored, so it applies to all reports
// opened in the same browser, until it is switched back to the browser's
// preference. This runs in the <head>, so the page is never shown in the
// wrong theme.
(function () {
  var key = "covr-report-theme";
  var media = window.matchMedia
    ? window.matchMedia("(prefers-color-scheme: dark)")
    : null;

  function stored() {
    try {
      return window.localStorage.getItem(key);
    } catch (e) {
      return null;
    }
  }

  // `null` follows the browser's preference
  var choice = stored();

  function preferred() {
    return media && media.matches ? "dark" : "light";
  }

  function current() {
    return choice === "dark" || choice === "light" ? choice : preferred();
  }

  // The class is namespaced, so a report doesn't change the styles of a
  // document it is included in
  function apply() {
    var dark = current() === "dark";
    document.documentElement.classList.toggle("covr-dark", dark);
    var buttons = document.querySelectorAll(".covr-theme-toggle");
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].setAttribute("aria-pressed", dark ? "true" : "false");
    }
  }

  function toggle() {
    var theme = current() === "dark" ? "light" : "dark";
    choice = theme === preferred() ? null : theme;
    try {
      if (choice === null) {
        window.localStorage.removeItem(key);
      } else {
        window.localStorage.setItem(key, choice);
      }
    } catch (e) {}
    apply();
  }

  apply();
  document.addEventListener("DOMContentLoaded", apply);
  if (media) {
    if (media.addEventListener) {
      media.addEventListener("change", apply);
    } else if (media.addListener) {
      media.addListener(apply);
    }
  }
  // Follow the theme chosen in other open reports
  window.addEventListener("storage", function (e) {
    if (e.key === key) {
      choice = e.newValue;
      apply();
    }
  });
  document.addEventListener("click", function (e) {
    if (e.target.closest && e.target.closest(".covr-theme-toggle")) {
      toggle();
    }
  });
})();
