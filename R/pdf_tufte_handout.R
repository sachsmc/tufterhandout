#' pdf format for tufte-handout
#' 
#' Produces a custom output format function in the style of Edward Tufte's handouts. This uses the 
#' tufte-handout latex document class.  Main features are plot hooks that put figures in the margin 
#' (\code{marginfigure = TRUE}), 
#' creates full-width figures (\code{fig.star = TRUE}), and allows "sidenotes". Sidenotes are used
#' instead of footnotes, for example \code{^[Content]}. See the 
#' package vignette for more details.
#' 
#' @param fig_width Default figure width
#' @param fig_height Default figure height
#' @param fig_crop Crop figures
#' @param highlight Code highlighting
#' @param keep_tex Preserve pandoc-generated tex document?
#' @param latex_engine Which latex engine to use
#' @param includes Named list of additional content to include in the document
#' @param pandoc_args Other arguments to pass to pandoc
#' 
#' @export
#' 


pdf_tufte_handout <- function(
                         fig_width = 6.5,
                         fig_height = 4.5,
                         fig_crop = TRUE,
                         highlight = "default",
                         keep_tex = FALSE,
                         latex_engine = "pdflatex",
                         includes = NULL,
                         pandoc_args = NULL) {
  
  require(rmarkdown)
  fig_caption <- TRUE
  # base pandoc options for all PDF output
  args <- c()
  
  # highlighting
  if (!is.null(highlight))
    highlight <- match.arg(highlight, rmarkdown:::highlighters())
  args <- c(args, rmarkdown:::pandoc_highlight_args(highlight))
  
  # latex engine
  latex_engine = match.arg(latex_engine, c("pdflatex", "lualatex", "xelatex"))
  args <- c(args, "--latex-engine", latex_engine)
  
  # content includes
  args <- c(args, rmarkdown:::includes_to_pandoc_args(includes))
  
  # args args
  args <- c(args, pandoc_args)
  
  # use a geometry filter when we are using the "default" template
    pre_processor <- NULL
  
  mypan_opts <- pandoc_options(to = "latex", keep_tex = TRUE, args = c(args, "--template", system.file("latex/tufte-handout.template", package = "tufterhandout")))  
   
  tmp_opts <- knitr_options_pdf(fig_width, fig_height, fig_crop)
  tmp_opts$opts_knit <- list(width = 50)
  tmp_opts$knit_hooks$plot <- function(x, options){
    
    name <- paste(options$fig.path, options$label, sep = '')
    if(!is.null(options$fig.cap)){
      
      caption <- paste("\\caption{", options$fig.cap, "}\n")
      
    } else {caption <- ""}
    
    if(!is.null(options$marginfigure) && options$marginfigure){
      
      return(paste('\\begin{marginfigure}\n \\includegraphics{', name, '}\n', caption, '\\end{marginfigure}\n', sep = ''))
      
    } else if(!is.null(options$fig.star) && options$fig.star) {
      
      return(paste('\\begin{figure*}\n \\includegraphics{', name, '}\n', caption, '\\end{figure*}\n', sep = ''))
      
    } else {
      
      return(paste('\\begin{figure}\n \\includegraphics{', name, '}\n', caption, '\\end{figure}\n', sep = ''))
      
    }
    
  }
   
  # return format
  output_format(
    knitr = tmp_opts,
    pandoc = mypan_opts,
    clean_supporting = !keep_tex,
    pre_processor = pre_processor
  )
}
