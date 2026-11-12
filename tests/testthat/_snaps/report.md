# covr.report_colors is validated (#529)

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must be a named character vector.
      i Use the names "covered", "missed" and/or "partial", e.g. `c(covered = "#0072B2", missed = "#E69F00")`.

---

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must be a named character vector.
      i Use the names "covered", "missed" and/or "partial", e.g. `c(covered = "#0072B2", missed = "#E69F00")`.

---

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must be a named character vector.
      i Use the names "covered", "missed" and/or "partial", e.g. `c(covered = "#0072B2", missed = "#E69F00")`.

---

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must contain valid R colors.
      x Can't find color "notacolor".

---

    Code
      file_report(cov, browse = FALSE)
    Condition
      Error:
      ! `covr.report_colors` must contain valid R colors.
      x Can't find color "notacolor".

# report_html() and file_report_html() are unchanged without branches

    Code
      writeLines(report_snapshot_html(cov))
    Output
      <div class="covr-report covr-colors-51bd73cd">
        <style>.covr-report.covr-colors-51bd73cd table tr.covered td{
        background-color:rgba(95,151,68,0.3)
      }
      .covr-report.covr-colors-51bd73cd table tr:hover.covered .num{
        background-color:rgba(95,151,68,0.7)
      }
      .covr-report.covr-colors-51bd73cd table tr.covered:hover td{
        -webkit-box-shadow:0 -2px 0 0 #5f9744 inset;
        -moz-box-shadow:0 -2px 0 0 #5f9744 inset;
        box-shadow:0 -2px 0 0 #5f9744 inset
      }
      .covr-report.covr-colors-51bd73cd table tr.missed td{
        background-color:rgba(185,73,71,0.3)
      }
      .covr-report.covr-colors-51bd73cd table tr:hover.missed .num{
        background-color:rgba(185,73,71,0.7)
      }
      .covr-report.covr-colors-51bd73cd table tr.missed:hover td{
        -webkit-box-shadow:0 -2px 0 0 #b94947 inset;
        -moz-box-shadow:0 -2px 0 0 #b94947 inset;
        box-shadow:0 -2px 0 0 #b94947 inset
      }
      .covr-report.covr-colors-51bd73cd{
        --covr-bar-high:#edfde7;
        --covr-bar-mid:#f9ffe5;
        --covr-bar-low:#fcece9;
      }
      html.covr-dark .covr-report.covr-colors-51bd73cd{
        --covr-bar-high:#374e33;
        --covr-bar-mid:#2c3a2e;
        --covr-bar-low:#583234;
      }
      </style>
        <div class="covr-header">
          <h2> coverage - 57.14%</h2>
          <button type="button" class="covr-theme-toggle" aria-pressed="false" aria-label="Dark mode" title="Toggle dark mode"><svg class="covr-icon-moon" aria-hidden="true" width="16" height="16" viewBox="0 0 16 16"><path fill="currentColor" d="M8.14 1.5A6.5 6.5 0 1 0 14.5 7.86A4.5 4.5 0 0 1 8.14 1.5Z"/></svg><svg class="covr-icon-sun" aria-hidden="true" width="16" height="16" viewBox="0 0 16 16"><circle cx="8" cy="8" r="3.2" fill="currentColor"/><path stroke="currentColor" stroke-width="1.5" stroke-linecap="round" d="M8 1v1.5M8 13.5V15M1 8h1.5M13.5 8H15M3 3l1.1 1.1M11.9 11.9 13 13M3 13l1.1-1.1M11.9 4.1 13 3"/></svg></button>
        </div>
        <div class="covr-tabset">
          <ul class="covr-tabs">
            <li class="active">
              <a href="#" data-value="Files">Files</a>
            </li>
            <li>
              <a href="#" data-value="Source">Source</a>
            </li>
          </ul>
          <div class="covr-tab-content">
            <div class="covr-tab-pane active" data-value="Files">
              <table class="covr-file-table">
                <thead>
                  <tr>
                    <th aria-sort="none">
                      <button type="button" class="covr-sort">File</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Lines</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Relevant</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Covered</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Missed</button>
                    </th>
                    <th class="covr-num" title="Average number of times each relevant line was run" aria-sort="none">
                      <button type="button" class="covr-sort">Hits/line</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Coverage</button>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="covr-file" data-sort="source.R">
                      <a href="#" class="covr-file-link">source.R</a>
                    </td>
                    <td class="covr-num" data-sort="15">15</td>
                    <td class="covr-num" data-sort="7">7</td>
                    <td class="covr-num" data-sort="4">4</td>
                    <td class="covr-num" data-sort="3">3</td>
                    <td class="covr-num" data-sort="0.6">0.6</td>
                    <td class="covr-num" style="background:linear-gradient(90deg, var(--covr-bar-low) 57.14%, transparent 57.14%)" data-sort="57.14">57.14%</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div class="covr-tab-pane" data-value="Source"><div class="covr-files"><div data-file="source.R" class="covr-hidden"><table class="table-condensed"><tbody>
      <tr class="never"><td class="num">1</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">sign_of &lt;- function(x) {</pre></td></tr>
      <tr class="covered"><td class="num">2</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">  if (x &gt; 0) {</pre></td></tr>
      <tr class="covered"><td class="num">3</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">    "positive"</pre></td></tr>
      <tr class="never"><td class="num">4</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">  } else {</pre></td></tr>
      <tr class="missed"><td class="num">5</td><td class="coverage">!</td><td class="covr-source"><pre class="language-r">    "negative"</pre></td></tr>
      <tr class="never"><td class="num">6</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">  }</pre></td></tr>
      <tr class="never"><td class="num">7</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      <tr class="never"><td class="num">8</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">maybe &lt;- function(x) {</pre></td></tr>
      <tr class="missed"><td class="num">9</td><td class="coverage">!</td><td class="covr-source"><pre class="language-r">  if (x) "yes"</pre></td></tr>
      <tr class="covered"><td class="num">10</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">  "done"</pre></td></tr>
      <tr class="never"><td class="num">11</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      <tr class="covered"><td class="num">12</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">both &lt;- function(x) if (x) 1 else 2</pre></td></tr>
      <tr class="never"><td class="num">13</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">describe &lt;- function(x) {</pre></td></tr>
      <tr class="missed"><td class="num">14</td><td class="coverage">!</td><td class="covr-source"><pre class="language-r">  switch(x, a = , b = "early", z = "late")</pre></td></tr>
      <tr class="never"><td class="num">15</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      </tbody></table></div>
      <script>(function(script) {
        var files = script ? script.parentNode : document;
        files.querySelectorAll('div.covr-files pre').forEach(function(block) {
          covrHljs.highlightElement(block);
        });
      })(document.currentScript);</script></div></div>
          </div>
        </div>
      </div>

---

    Code
      writeLines(report_snapshot_html(cov, file_report_html))
    Output
      <div class="covr-report covr-colors-51bd73cd">
        <style>.covr-report.covr-colors-51bd73cd table tr.covered td{
        background-color:rgba(95,151,68,0.3)
      }
      .covr-report.covr-colors-51bd73cd table tr:hover.covered .num{
        background-color:rgba(95,151,68,0.7)
      }
      .covr-report.covr-colors-51bd73cd table tr.covered:hover td{
        -webkit-box-shadow:0 -2px 0 0 #5f9744 inset;
        -moz-box-shadow:0 -2px 0 0 #5f9744 inset;
        box-shadow:0 -2px 0 0 #5f9744 inset
      }
      .covr-report.covr-colors-51bd73cd table tr.missed td{
        background-color:rgba(185,73,71,0.3)
      }
      .covr-report.covr-colors-51bd73cd table tr:hover.missed .num{
        background-color:rgba(185,73,71,0.7)
      }
      .covr-report.covr-colors-51bd73cd table tr.missed:hover td{
        -webkit-box-shadow:0 -2px 0 0 #b94947 inset;
        -moz-box-shadow:0 -2px 0 0 #b94947 inset;
        box-shadow:0 -2px 0 0 #b94947 inset
      }
      .covr-report.covr-colors-51bd73cd{
        --covr-bar-high:#edfde7;
        --covr-bar-mid:#f9ffe5;
        --covr-bar-low:#fcece9;
      }
      html.covr-dark .covr-report.covr-colors-51bd73cd{
        --covr-bar-high:#374e33;
        --covr-bar-mid:#2c3a2e;
        --covr-bar-low:#583234;
      }
      </style>
        <div class="covr-header">
          <h2>source.R - 57.14%</h2>
          <button type="button" class="covr-theme-toggle" aria-pressed="false" aria-label="Dark mode" title="Toggle dark mode"><svg class="covr-icon-moon" aria-hidden="true" width="16" height="16" viewBox="0 0 16 16"><path fill="currentColor" d="M8.14 1.5A6.5 6.5 0 1 0 14.5 7.86A4.5 4.5 0 0 1 8.14 1.5Z"/></svg><svg class="covr-icon-sun" aria-hidden="true" width="16" height="16" viewBox="0 0 16 16"><circle cx="8" cy="8" r="3.2" fill="currentColor"/><path stroke="currentColor" stroke-width="1.5" stroke-linecap="round" d="M8 1v1.5M8 13.5V15M1 8h1.5M13.5 8H15M3 3l1.1 1.1M11.9 11.9 13 13M3 13l1.1-1.1M11.9 4.1 13 3"/></svg></button>
        </div>
        <div class="covr-files"><div data-file="source.R" class=""><table class="table-condensed"><tbody>
      <tr class="never"><td class="num">1</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">sign_of &lt;- function(x) {</pre></td></tr>
      <tr class="covered"><td class="num">2</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">  if (x &gt; 0) {</pre></td></tr>
      <tr class="covered"><td class="num">3</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">    "positive"</pre></td></tr>
      <tr class="never"><td class="num">4</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">  } else {</pre></td></tr>
      <tr class="missed"><td class="num">5</td><td class="coverage">!</td><td class="covr-source"><pre class="language-r">    "negative"</pre></td></tr>
      <tr class="never"><td class="num">6</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">  }</pre></td></tr>
      <tr class="never"><td class="num">7</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      <tr class="never"><td class="num">8</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">maybe &lt;- function(x) {</pre></td></tr>
      <tr class="missed"><td class="num">9</td><td class="coverage">!</td><td class="covr-source"><pre class="language-r">  if (x) "yes"</pre></td></tr>
      <tr class="covered"><td class="num">10</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">  "done"</pre></td></tr>
      <tr class="never"><td class="num">11</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      <tr class="covered"><td class="num">12</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">both &lt;- function(x) if (x) 1 else 2</pre></td></tr>
      <tr class="never"><td class="num">13</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">describe &lt;- function(x) {</pre></td></tr>
      <tr class="missed"><td class="num">14</td><td class="coverage">!</td><td class="covr-source"><pre class="language-r">  switch(x, a = , b = "early", z = "late")</pre></td></tr>
      <tr class="never"><td class="num">15</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      </tbody></table></div>
      <script>(function(script) {
        var files = script ? script.parentNode : document;
        files.querySelectorAll('div.covr-files pre').forEach(function(block) {
          covrHljs.highlightElement(block);
        });
      })(document.currentScript);</script></div>
      </div>

# report_html() shows the branches taken on each line (#751)

    Code
      writeLines(report_snapshot_html(cov))
    Output
      <div class="covr-report covr-colors-51bd73cd">
        <style>.covr-report.covr-colors-51bd73cd table tr.covered td{
        background-color:rgba(95,151,68,0.3)
      }
      .covr-report.covr-colors-51bd73cd table tr:hover.covered .num{
        background-color:rgba(95,151,68,0.7)
      }
      .covr-report.covr-colors-51bd73cd table tr.covered:hover td{
        -webkit-box-shadow:0 -2px 0 0 #5f9744 inset;
        -moz-box-shadow:0 -2px 0 0 #5f9744 inset;
        box-shadow:0 -2px 0 0 #5f9744 inset
      }
      .covr-report.covr-colors-51bd73cd table tr.missed td{
        background-color:rgba(185,73,71,0.3)
      }
      .covr-report.covr-colors-51bd73cd table tr:hover.missed .num{
        background-color:rgba(185,73,71,0.7)
      }
      .covr-report.covr-colors-51bd73cd table tr.missed:hover td{
        -webkit-box-shadow:0 -2px 0 0 #b94947 inset;
        -moz-box-shadow:0 -2px 0 0 #b94947 inset;
        box-shadow:0 -2px 0 0 #b94947 inset
      }
      .covr-report.covr-colors-51bd73cd table tr.partial td{
        background-color:rgba(212,167,44,0.3)
      }
      .covr-report.covr-colors-51bd73cd table tr:hover.partial .num{
        background-color:rgba(212,167,44,0.7)
      }
      .covr-report.covr-colors-51bd73cd table tr.partial:hover td{
        -webkit-box-shadow:0 -2px 0 0 #d4a72c inset;
        -moz-box-shadow:0 -2px 0 0 #d4a72c inset;
        box-shadow:0 -2px 0 0 #d4a72c inset
      }
      .covr-report.covr-colors-51bd73cd .covr-branch-missed{
        background-color:rgba(185,73,71,0.3)
      }
      .covr-report.covr-colors-51bd73cd{
        --covr-bar-high:#edfde7;
        --covr-bar-mid:#f9ffe5;
        --covr-bar-low:#fcece9;
      }
      html.covr-dark .covr-report.covr-colors-51bd73cd{
        --covr-bar-high:#374e33;
        --covr-bar-mid:#2c3a2e;
        --covr-bar-low:#583234;
      }
      </style>
        <div class="covr-header">
          <h2> coverage - 57.14% (branches 66.67%)</h2>
          <button type="button" class="covr-theme-toggle" aria-pressed="false" aria-label="Dark mode" title="Toggle dark mode"><svg class="covr-icon-moon" aria-hidden="true" width="16" height="16" viewBox="0 0 16 16"><path fill="currentColor" d="M8.14 1.5A6.5 6.5 0 1 0 14.5 7.86A4.5 4.5 0 0 1 8.14 1.5Z"/></svg><svg class="covr-icon-sun" aria-hidden="true" width="16" height="16" viewBox="0 0 16 16"><circle cx="8" cy="8" r="3.2" fill="currentColor"/><path stroke="currentColor" stroke-width="1.5" stroke-linecap="round" d="M8 1v1.5M8 13.5V15M1 8h1.5M13.5 8H15M3 3l1.1 1.1M11.9 11.9 13 13M3 13l1.1-1.1M11.9 4.1 13 3"/></svg></button>
        </div>
        <div class="covr-tabset">
          <ul class="covr-tabs">
            <li class="active">
              <a href="#" data-value="Files">Files</a>
            </li>
            <li>
              <a href="#" data-value="Source">Source</a>
            </li>
          </ul>
          <div class="covr-tab-content">
            <div class="covr-tab-pane active" data-value="Files">
              <table class="covr-file-table">
                <thead>
                  <tr>
                    <th aria-sort="none">
                      <button type="button" class="covr-sort">File</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Lines</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Relevant</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Covered</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Missed</button>
                    </th>
                    <th class="covr-num" title="Average number of times each relevant line was run" aria-sort="none">
                      <button type="button" class="covr-sort">Hits/line</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Branches</button>
                    </th>
                    <th class="covr-num" aria-sort="none">
                      <button type="button" class="covr-sort">Coverage</button>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="covr-file" data-sort="source.R">
                      <a href="#" class="covr-file-link">source.R</a>
                    </td>
                    <td class="covr-num" data-sort="15">15</td>
                    <td class="covr-num" data-sort="7">7</td>
                    <td class="covr-num" data-sort="4">4</td>
                    <td class="covr-num" data-sort="3">3</td>
                    <td class="covr-num" data-sort="0.6">0.6</td>
                    <td class="covr-num" data-sort="66.67">66.67%</td>
                    <td class="covr-num" style="background:linear-gradient(90deg, var(--covr-bar-low) 57.14%, transparent 57.14%)" data-sort="57.14">57.14%</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div class="covr-tab-pane" data-value="Source"><div class="covr-files"><div data-file="source.R" class="covr-hidden"><table class="table-condensed"><tbody>
      <tr class="never"><td class="num">1</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">sign_of &lt;- function(x) {</pre></td></tr>
      <tr class="partial"><td class="num">2</td><td class="coverage">1<em>x</em><span class="covr-branches" tabindex="0">1/2<span class="covr-branch-detail"><span class="covr-branch">TRUE: 1</span><span class="covr-branch covr-branch-missed">FALSE: 0</span></span></span></td><td class="covr-source"><pre class="language-r">  if (x &gt; 0) {</pre></td></tr>
      <tr class="covered"><td class="num">3</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">    "positive"</pre></td></tr>
      <tr class="never"><td class="num">4</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">  } else {</pre></td></tr>
      <tr class="missed"><td class="num">5</td><td class="coverage">!</td><td class="covr-source"><pre class="language-r">    "negative"</pre></td></tr>
      <tr class="never"><td class="num">6</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">  }</pre></td></tr>
      <tr class="never"><td class="num">7</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      <tr class="never"><td class="num">8</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">maybe &lt;- function(x) {</pre></td></tr>
      <tr class="partial"><td class="num">9</td><td class="coverage">!<span class="covr-branches" tabindex="0">1/2<span class="covr-branch-detail"><span class="covr-branch covr-branch-missed">TRUE: 0</span><span class="covr-branch">FALSE: 1</span></span></span></td><td class="covr-source"><pre class="language-r">  if (x) "yes"</pre></td></tr>
      <tr class="covered"><td class="num">10</td><td class="coverage">1<em>x</em></td><td class="covr-source"><pre class="language-r">  "done"</pre></td></tr>
      <tr class="never"><td class="num">11</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      <tr class="covered"><td class="num">12</td><td class="coverage">1<em>x</em><span class="covr-branches" tabindex="0">2/2<span class="covr-branch-detail"><span class="covr-branch">TRUE: 1</span><span class="covr-branch">FALSE: 1</span></span></span></td><td class="covr-source"><pre class="language-r">both &lt;- function(x) if (x) 1 else 2</pre></td></tr>
      <tr class="never"><td class="num">13</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">describe &lt;- function(x) {</pre></td></tr>
      <tr class="partial"><td class="num">14</td><td class="coverage">!<span class="covr-branches" tabindex="0">2/3<span class="covr-branch-detail"><span class="covr-branch">a, b: 1</span><span class="covr-branch covr-branch-missed">z: 0</span><span class="covr-branch">&lt;no match&gt;: 1</span></span></span></td><td class="covr-source"><pre class="language-r">  switch(x, a = , b = "early", z = "late")</pre></td></tr>
      <tr class="never"><td class="num">15</td><td class="coverage"></td><td class="covr-source"><pre class="language-r">}</pre></td></tr>
      </tbody></table></div>
      <script>(function(script) {
        var files = script ? script.parentNode : document;
        files.querySelectorAll('div.covr-files pre').forEach(function(block) {
          covrHljs.highlightElement(block);
        });
      })(document.currentScript);</script></div></div>
          </div>
        </div>
      </div>

# file_report_html() needs a single file

    Code
      file_report_html(cov, file = c("a.R", "b.R"))
    Condition
      Error:
      ! `file` must be a single file name.

# report() and file_report() require htmltools

    Code
      report(cov, browse = FALSE)
    Condition
      Error:
      ! `report()` requires the htmltools package.
      i Install it with `install.packages("htmltools")`.

---

    Code
      file_report(cov, browse = FALSE)
    Condition
      Error:
      ! `report()` requires the htmltools package.
      i Install it with `install.packages("htmltools")`.

# addin_report() reports the coverage of the active project

    Code
      addin_report()
    Message
      Calculating test coverage for TestS4...

# addin_report() uses the working directory without a project

    Code
      addin_report()
    Message
      Calculating test coverage for TestS4...

