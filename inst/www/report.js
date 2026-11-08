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
    // The text of the link can have whitespace added by Quarto
    var file = link.closest("td").getAttribute("data-sort");
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

  // Sort the file list by a column, in ascending order first, then switching
  // between descending and ascending. Cells without a number sort first.
  function sortTable(button) {
    var th = button.parentNode;
    var headers = th.parentNode.children;
    var index = Array.prototype.indexOf.call(headers, th);
    var ascending = th.getAttribute("aria-sort") !== "ascending";
    var numeric = th.classList.contains("covr-num");
    for (var i = 0; i < headers.length; i++) {
      headers[i].setAttribute("aria-sort", "none");
    }
    th.setAttribute("aria-sort", ascending ? "ascending" : "descending");

    var tbody = th.closest("table").tBodies[0];
    var rows = Array.prototype.slice.call(tbody.rows);
    function key(row) {
      var value = row.cells[index].getAttribute("data-sort");
      if (!numeric) {
        return value;
      }
      return value === "" ? -Infinity : Number(value);
    }
    rows.sort(function (a, b) {
      var x = key(a);
      var y = key(b);
      var order = numeric ? (x < y ? -1 : x > y ? 1 : 0) : x.localeCompare(y);
      return ascending ? order : -order;
    });
    for (var j = 0; j < rows.length; j++) {
      tbody.appendChild(rows[j]);
    }
  }

  document.addEventListener("click", function (e) {
    if (!e.target.closest) {
      return;
    }
    var sort = e.target.closest(".covr-report button.covr-sort");
    if (sort) {
      sortTable(sort);
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
