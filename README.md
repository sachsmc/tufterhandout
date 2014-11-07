tufterhandout
=============

[![Build Status](https://travis-ci.org/sachsmc/tufterhandout.png?branch=master)](https://travis-ci.org/sachsmc/tufterhandout)

Output formats for Tufte-style handouts in html for Rmarkdown. See it in action here <http://sachsmc.github.io/tufterhandout>. 

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
In html, sidenotes are created with the tag `<aside></aside>`. You can even put code chunks in `aside`. Margin figures use the knitr option `marginfigure = TRUE` and full width figures use the knitr option `fig.star = TRUE`. Make use of the `fig.cap` option to specify the figure captions. 

See the help files for complete options and see the [homepage](http://sachsmc.github.io/tufterhandout) for an example. Options can be passed via the header:

```
output: 
    tufterhandout::html_tufte_handout:
        keep_md: true
        theme: cerulean
```
