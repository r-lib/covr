// The tabs of the reports and the links to their files. Each report only
// changes its own elements, so a document can include several reports.
(function () {
  // Show a tab, remembering the scroll position of each tab, so returning to
  // the file list after viewing a file puts you back where you were.
  function showTab(link) {
    var tabset = link.closest(".covr-tabset");
    var active = tabset.querySelector(".covr-tabs > li.active > a");
    if (active === link) {
      return;
    }
    if (active) {
      active.setAttribute("data-scroll", window.pageYOffset);
      active.parentNode.classList.remove("active");
    }
    link.parentNode.classList.add("active");

    var value = link.getAttribute("data-value");
    var panes = tabset.querySelectorAll(".covr-tab-content > .covr-tab-pane");
    for (var i = 0; i < panes.length; i++) {
      panes[i].classList.toggle(
        "active",
        panes[i].getAttribute("data-value") === value
      );
    }

    var scroll = link.getAttribute("data-scroll");
    if (scroll === null) {
      // Show the start of the tab content, just below the sticky tabs
      var top = tabset.getBoundingClientRect().top + window.pageYOffset;
      scroll = Math.min(window.pageYOffset, top);
    }
    window.scrollTo(window.pageXOffset, Number(scroll));
  }

  // Show a file in the source tab, starting at the top of the file
  function showFile(link) {
    var report = link.closest(".covr-report");
    var file = link.textContent;
    var files = report.querySelectorAll(".covr-files > div");
    for (var i = 0; i < files.length; i++) {
      files[i].classList.toggle(
        "covr-hidden",
        files[i].getAttribute("data-file") !== file
      );
    }
    var source = report.querySelector('.covr-tabs a[data-value="Source"]');
    source.textContent = file;
    source.removeAttribute("data-scroll");
    showTab(source);
  }

  document.addEventListener("click", function (e) {
    if (!e.target.closest) {
      return;
    }
    var tab = e.target.closest(".covr-report .covr-tabs a");
    if (tab) {
      e.preventDefault();
      showTab(tab);
      return;
    }
    var file = e.target.closest(".covr-report a.covr-file-link");
    if (file) {
      e.preventDefault();
      showFile(file);
    }
  });
})();
