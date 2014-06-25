tufterhandout
=============

Output formats for Tufte-style handouts in pdf and html for Rmarkdown. See it in action here <http://sachsmc.github.io/tufterhandout>. 

## Installation

```r
devtools::install_github("tufterhandout", "sachsmc")
```

## Usage

When authoring a document in rmarkdown, simply specify the output format in the front-matter:

```
output: 
    tufterhandout::html_tufte_handout
```
In html, sidenotes are created with the tag `<emph class="sidenote"></emph>`. Margin figures use the knitr option `marginfigure = TRUE` and full width figures use the knitr option `fig.star = TRUE`. Make use of the `fig.cap` option to specify the figure captions. 

or

```
output: 
    tufterhandout::pdf_tufte_handout
```

In pdf format, footnotes are replaced with sidenotes. You can use the pandoc command `^[sidenote content goes in here]`. The same options for figures are there. 

See the help files for complete options. 
