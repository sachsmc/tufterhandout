#' pdf format for tufte-handout
#' 
#' @export
#' 

pdf_tufte_handout <- function(
                         fig_width = 6.5,
                         fig_height = 4.5,
                         fig_crop = TRUE,
                         fig_caption = TRUE,
                         highlight = "default",
                         keep_tex = FALSE,
                         latex_engine = "pdflatex",
                         includes = NULL,
                         pandoc_args = NULL) {
  
  require(rmarkdown)
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
