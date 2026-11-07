// Remember the scroll position of each tab, so returning to the file list
// after viewing a file puts you back where you were.
$(document).on("hide.bs.tab", "ul.nav-tabs a[data-toggle=tab]", function () {
  $(this).data("scroll", window.scrollY);
});

$(document).on("shown.bs.tab", "ul.nav-tabs a[data-toggle=tab]", function () {
  var scroll = $(this).data("scroll");
  if (scroll === undefined || scroll === null) {
    // Show the start of the tab content, just below the sticky tabs
    var top = $(this).closest(".tabbable").offset().top;
    scroll = Math.min(window.scrollY, top);
  }
  window.scrollTo(window.scrollX, scroll);
});
