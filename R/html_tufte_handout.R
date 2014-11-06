#' @import htmltools
#' @import rmarkdown
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
#'
#' @export
#'

html_tufte_handout <- function(self_contained = TRUE,
                               theme = "default",
                               lib_dir = NULL,
                               keep_md = FALSE,
                               mathjax = "default",
                               pandoc_args = NULL) {

  dependency_resolver <- html_dependency_resolver
  copy_resources <- FALSE
  extra_dependencies <- NULL
  bootstrap_compatible <- FALSE

  args <- c()

 # self contained document
    if (copy_resources)
      stop("Local resource copying is incompatible with self-contained documents.")
    rmarkdown:::validate_self_contained(mathjax)
    args <- c(args, "--self-contained")


  # custom args
  args <- c(args, pandoc_args)

  preserved_chunks <- character()

  output_dir <- ""

  pre_processor <- function (metadata, input_file, runtime, knit_meta,
                             files_dir, output_dir) {

    args <- c()

    # use files_dir as lib_dir if not explicitly specified
    if (is.null(lib_dir))
      lib_dir <<- files_dir

    # copy supplied output_dir (for use in post-processor)
    output_dir <<- output_dir

    # handle theme
    if (!is.null(theme)) {
      theme <- match.arg(theme, rmarkdown:::themes())
      if (identical(theme, "default"))
        theme <- "bootstrap"
      args <- c(args, "--variable", paste("theme:", theme, sep=""))
    }

    # resolve and inject extras, including dependencies specified by the format
    # and dependencies specified by the user (via extra_dependencies)
    format_deps <- list()
    format_deps <- append(format_deps, extra_dependencies)
    if (!is.null(theme)) {
      format_deps <- append(format_deps, list(html_dependency_jquery(),
                                              html_dependency_bootstrap(theme)))
    }
    else if (isTRUE(bootstrap_compatible) && identical(runtime, "shiny")) {
      # If we can add bootstrap for Shiny, do it
      format_deps <- append(format_deps,
                            list(html_dependency_bootstrap("bootstrap")))
    }

    extras <- html_extras_for_document(knit_meta, runtime, dependency_resolver,
                                       format_deps)
    args <- c(args, pandoc_html_extras_args(extras, self_contained, lib_dir,
                                            output_dir))

    # mathjax
    args <- c(args, rmarkdown:::pandoc_mathjax_args(mathjax,
                                        template = "default",
                                        self_contained,
                                        lib_dir))

    # The input file is converted to UTF-8 from its native encoding prior
    # to calling the preprocessor (see ::render)
    input_str <- readLines(input_file, warn = FALSE, encoding = "UTF-8")
    preserve <- extractPreserveChunks(input_str)
    if (!identical(preserve$value, input_str))
      writeLines(preserve$value, input_file, useBytes = TRUE)
    preserved_chunks <<- preserve$chunks

    args
  }

  post_processor <- function(metadata, input_file, output_file, clean, verbose) {
    # if there are no preserved chunks to restore and no resource to copy then no
    # post-processing is necessary
    if (length(preserved_chunks) == 0 && !isTRUE(copy_resources) && self_contained)
      return(output_file)

    # read the output file
    output_str <- readLines(output_file, warn = FALSE, encoding = "UTF-8")

    # if we preserved chunks, restore them
    if (length(preserved_chunks) > 0)
      output_str <- restorePreserveChunks(output_str, preserved_chunks)

    # The copy_resources flag copies all the resources referenced in the
    # document to its supporting files directory, and rewrites the document to
    # use the copies from that directory.
    if (copy_resources) {
      resource_copier <- function(res_src, src) {
        in_file <- utils::URLdecode(src)
        if (length(in_file) && file.exists(in_file)) {

          # create a unique image name in the library folder and copy the image
          # there
          target_res_file <- paste(file.path(lib_dir, createUniqueId(16)),
                                   tools::file_ext(in_file), sep = ".")
          file.copy(in_file, target_res_file)

          # replace the reference in the document
          res_src <- sub(src, rmarkdown:::relative_to(output_dir, target_res_file), res_src)
        }
        res_src
      }
      output_str <- rmarkdown:::process_images(output_str, resource_copier)
      output_str <- rmarkdown:::process_css(output_str, resource_copier)
    } else if (!self_contained) {
      # if we're not self-contained, find absolute references to the output
      # directory and replace them with relative ones
      image_relative <- function(img_src, src) {
        in_file <- utils::URLdecode(src)
        if (length(in_file) && file.exists(in_file)) {
          img_src <- sub(
            src, utils::URLencode(rmarkdown:::relative_to(output_dir, in_file)), img_src)
        }
        img_src
      }
      output_str <- rmarkdown:::process_images(output_str, image_relative)
    }

    writeLines(output_str, output_file, useBytes = TRUE)
    output_file
  }

 mypan_opts <- pandoc_options(to = "html", args = c(args, "--section-divs", "--include-before-body", system.file("html/header.html", package = "tufterhandout")))

 myknit_opts <- knitr_options(opts_knit = list(width = 80),  knit_hooks = list(plot = function(x, options){
   name <- paste0(knitr::fig_path(options = options), ".png")
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
    pre_processor = pre_processor,
    post_processor = post_processor
  )
}
