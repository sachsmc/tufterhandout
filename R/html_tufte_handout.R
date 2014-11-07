#' @import rmarkdown
#' @import knitr
NULL

#' html format for tufte-handout
#'
#' Produces a custom output format function in the style of Edward Tufte's handouts. This
#' essentially recreates the tufte-handout latex document class using bootstrap.
#' Main features are plot hooks that put figures in the margin (\code{marginfigure = TRUE}),
#' creates full-width figures (\code{fig.star = TRUE}), and allows "sidenotes". To create a sidenote,
#' some raw html is required. Usage is \code{<aside> Content </aside>}. See the
#' package vignette for more details.
#'
#' @param self_contained Include all dependencies
#' @param theme Bootstrap theme
#' @param lib_dir Local directory to copy assets
#' @param keep_md Keep knitr-generated markdown
#' @param mathjax Include mathjax, "local" or "default"
#' @param pandoc_args Other arguments to pass to pandoc
#' @param ... Additional function arguments to pass to the base R Markdown HTML
#'   output formatter
#' @export
#'

html_tufte_handout <- function(self_contained = TRUE,
                               theme = "default",
                               lib_dir = NULL,
                               keep_md = FALSE,
                               mathjax = "default",
                               pandoc_args = NULL, ...) {

 mypan_opts <- pandoc_options(to = "html", args = c("--section-divs", "--css", system.file("tufterhandout.css", package = "tufterhandout")))

 myknit_opts <- knitr_options(opts_knit = list(width = 80),  knit_hooks = list(plot = function(name, options){

   if(!is.null(options$fig.cap)){

     caption <-  paste('<p class="caption">', options$fig.cap, '</p>', sep = "")

   } else { caption <- "" }

   if(!is.null(options$marginfigure) && options$marginfigure){

     hadj <- (length(options$code) + 2) * 1.5
     return(paste('<aside style="margin-top:-', floor(hadj), 'em"> <img src="', name, '">', caption, '</aside>', sep = ''))

   }  else if(!is.null(options$fig.star) && options$fig.star) {

     return(paste('<div class="fullwidth"> <img src="', name, '"><aside style="margin-top: 0em">', caption, '<aside></div>', sep = ''))

   } else {

     return(paste('<p><img src="', name, '"> <aside>', caption, '</aside></p>', sep = ''))

   }
 }))

  output_format(
    knitr = myknit_opts,
    pandoc =  mypan_opts,
    clean_supporting = FALSE,
    keep_md = keep_md,
    base_format = html_document(theme = theme,
                                self_contained = self_contained,
                                lib_dir = lib_dir,
                                mathjax = mathjax,
                                pandoc_args = pandoc_args,
                                ...)
  )
}
