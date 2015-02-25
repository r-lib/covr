function highlight() {
  $('#table pre').each(function(i, block) {
    hljs.highlightBlock(block);
  });
}
Shiny.addCustomMessageHandler("highlight", function(x) {
  console.log("hi");
  highlight()
});
