#' @import htmltools
NULL

# create an html dependency for our embedded jquery
html_dependency_jquery <- function()  {
  htmlDependency(name = "jquery",
                 version = "1.11.0",
                 src = rmarkdown_system_file("rmd/h/jquery-1.11.0"),
                 script = "jquery.min.js")
}

# create an html dependency for our embedded bootstrap
html_dependency_bootstrap <- function(theme) {
  htmlDependency(name = "bootstrap",
                 version = "2.3.2",
                 src = rmarkdown_system_file("rmd/h/bootstrap-2.3.2"),
                 meta = list(viewport = "width=device-width, initial-scale=1.0"),
                 script = "js/bootstrap.min.js",
                 stylesheet = c(paste("css/", theme, ".min.css", sep=""),
                                "css/bootstrap-responsive.min.css"))
}

# flattens an arbitrarily nested list and returns all of the html_dependency
# objects it contains
flatten_html_dependencies <- function(knit_meta) {
  
  all_dependencies <- list()
  
  # knit_meta is a list of 'meta' attributes returned from custom knit_print
  # functions. since the 'meta' attribute could either be an html dependency or
  # a list of dependencies we recurse on lists that aren't named
  for (dep in knit_meta) {
    if (is.null(names(dep)) && is.list(dep)) {
      inner_dependencies <- flatten_html_dependencies(dep)
      all_dependencies <- append(all_dependencies, inner_dependencies)
    }
    else if (is_html_dependency(dep)) {
      all_dependencies[[length(all_dependencies) + 1]] <- dep
    }
  }
  
  all_dependencies
}

# consolidate dependencies (use latest versions and remove duplicates). this
# routine is the default implementation for version dependency resolution;
# formats may specify their own.
html_dependency_resolver <- function(all_dependencies) {
  
  dependencies <- htmltools::resolveDependencies(all_dependencies)
  
  # validate each surviving dependency
  lapply(dependencies, validate_html_dependency)
  
  # return the consolidated dependencies
  dependencies
}

html_reference_path <- function(path, lib_dir, output_dir) {
  # write the full OS-specific path if no library
  if (is.null(lib_dir))
    pandoc_path_arg(path)
  else
    relative_to(output_dir, path)
}

# return the html dependencies as an HTML string suitable for inclusion
# in the head of a document
html_dependencies_as_string <- function(dependencies, lib_dir, output_dir) {
  
  if (!is.null(lib_dir)) {
    dependencies <- lapply(dependencies, copyDependencyToDir, lib_dir)
    dependencies <- lapply(dependencies, makeDependencyRelative, output_dir)
  }
  return(renderDependencies(dependencies, "file", encodeFunc = identity,
                            hrefFilter = function(path) {
                              html_reference_path(path, lib_dir, output_dir)
                            })
  )
}

# check class of passed list for 'html_dependency'
is_html_dependency <- function(list) {
  inherits(list, "html_dependency")
}

# validate that the passed list is a correctly formed html_dependency
validate_html_dependency <- function(list) {
  
  # ensure it's the right class
  if (!is_html_dependency(list))
    stop("passed object is not of class html_dependency", call. = FALSE)
  
  # validate required fields
  if (is.null(list$name))
    stop("name for html_dependency not provided", call. = FALSE)
  if (is.null(list$version))
    stop("version for html_dependency not provided", call. = FALSE)
  if (is.null(list$src$file))
    stop("path for html_dependency not provided", call. = FALSE)
  if (!file.exists(list$src$file))
    stop("path for html_dependency not found: ", list$src$file, call. = FALSE)
  
  list
}

# check if the passed knit_meta has any html dependencies
has_html_dependencies <- function(knit_meta) {
  
  if (inherits(knit_meta, "html_dependency"))
    return(TRUE)
  
  else if (is.list(knit_meta)) {
    for (dep in knit_meta) {
      if (is.null(names(dep))) {
        if (has_html_dependencies(dep))
          return(TRUE)
      } else {
        if (inherits(dep, "html_dependency"))
          return(TRUE)
      }
    }
    
    FALSE
  } else {
    FALSE
  }
}


# resolve the html extras for a document (dependencies and arbitrary html to
# inject into the document)
html_extras_for_document <- function(knit_meta, runtime, dependency_resolver,
                                     format_deps = NULL) {
  
  extras <- list()
  
  # merge the dependencies discovered with the dependencies of this format and
  # dependencies discovered in knit_meta
  all_dependencies <- if (is.null(format_deps)) list() else format_deps
  all_dependencies <- append(all_dependencies, flatten_html_dependencies(knit_meta))
  extras$dependencies <- dependency_resolver(all_dependencies)
  
  # return extras
  extras
}

# convert html extras to the pandoc args required to include them
pandoc_html_extras_args <- function(extras, self_contained, lib_dir,
                                    output_dir) {
  
  args <- c()
  
  # dependencies
  dependencies <- extras$dependencies
  if (length(dependencies) > 0) {
    if (self_contained)
      file <- as_tmpfile(html_dependencies_as_string(dependencies, NULL, NULL))
    else
      file <- as_tmpfile(html_dependencies_as_string(dependencies, lib_dir,
                                                     output_dir))
    args <- c(args, pandoc_include_args(in_header = file))
  }
  
  # extras
  args <- c(args, pandoc_include_args(
    in_header = as_tmpfile(extras$in_header),
    before_body = as_tmpfile(extras$before_body),
    after_body = as_tmpfile(extras$after_body)))
  
  args
}


createUniqueId <- function(bytes) {
  paste(as.hexmode(sample(256, bytes)-1), collapse="")
}

is_windows <- function() {
  identical(.Platform$OS.type, "windows")
}

# determine the output file for a pandoc conversion
pandoc_output_file <- function(input, pandoc_options) {
  to <- pandoc_options$to
  if (!is.null(pandoc_options$ext))
    ext <- pandoc_options$ext
  else if (to %in% c("latex", "beamer"))
    ext <- ".pdf"
  else if (to %in% c("html", "html5", "s5", "slidy",
                     "slideous", "dzslides", "revealjs"))
    ext <- ".html"
  else if (grepl("^markdown", to)) {
    if (!identical(tolower(tools::file_ext(input)), "md"))
      ext <- ".md"
    else {
      ext <- paste(".", strsplit(to, "[\\+\\-]")[[1]][[1]], sep = "")
    }
  }
  else
    ext <- paste(".", to, sep = "")
  output <- paste(tools::file_path_sans_ext(input), ext, sep = "")
  basename(output)
}


rmarkdown_system_file <- function(file) {
  system.file(file, package = "rmarkdown")
}

from_rmarkdown <- function(implicit_figures = TRUE) {
  rmarkdown_format(ifelse(implicit_figures, "", "-implicit_figures"))
}

is_null_or_string <- function(text) {
  is.null(text) || (is.character(text) && (length(text) == 1))
}

read_lines_utf8 <- function(file, encoding) {
  
  # read the file
  lines <- readLines(file, warn = FALSE)
  
  # normalize encoding to iconv compatible form
  if (identical(encoding, "native.enc"))
    encoding <- ""
  
  # convert to utf8
  if (!identical(encoding, "UTF-8"))
    iconv(lines, from = encoding, to = "UTF-8")
  else
    lines
}

file_name_without_spaces <- function(file) {
  name <- gsub(' ', '_', basename(file), fixed = TRUE)
  dir <- dirname(file)
  if (nzchar(dir) && !identical(dir, "."))
    file.path(dir, name)
  else
    name
}

# return a string as a tempfile
as_tmpfile <- function(str) {
  if (length(str) > 0) {
    str_tmpfile <- tempfile("rmarkdown-str", fileext = ".html")
    writeLines(str, str_tmpfile)
    str_tmpfile
  } else {
    NULL
  }
}

file_with_ext <- function(file, ext) {
  paste(tools::file_path_sans_ext(file), ".", ext, sep = "")
}


file_with_meta_ext <- function(file, meta_ext, ext = tools::file_ext(file)) {
  paste(tools::file_path_sans_ext(file),
        ".", meta_ext, ".", ext, sep = "")
}

knitr_files_dir <- function(file) {
  paste(tools::file_path_sans_ext(file), "_files", sep = "")
}

knitr_cache_dir <- function(file, pandoc_to) {
  paste(tools::file_path_sans_ext(file), "_cache/", pandoc_to, "/", sep = "")
}


highlighters <- function() {
  c("default",
    "tango",
    "pygments",
    "kate",
    "monochrome",
    "espresso",
    "zenburn",
    "haddock")
}

merge_lists <- function (base_list, overlay_list, recursive = TRUE) {
  if (length(base_list) == 0)
    overlay_list
  else if (length(overlay_list) == 0)
    base_list
  else {
    merged_list <- base_list
    for (name in names(overlay_list)) {
      base <- base_list[[name]]
      overlay <- overlay_list[[name]]
      if (is.list(base) && is.list(overlay) && recursive)
        merged_list[[name]] <- merge_lists(base, overlay)
      else {
        merged_list[[name]] <- NULL
        merged_list <- append(merged_list,
                              overlay_list[which(names(overlay_list) %in% name)])
      }
    }
    merged_list
  }
}

strip_white <- function (x)
{
  if (!length(x))
    return(x)
  while (is_blank(x[1])) {
    x = x[-1]
    if (!length(x))
      return(x)
  }
  while (is_blank(x[(n <- length(x))])) {
    x = x[-n]
    if (n < 2)
      return(x)
  }
  x
}

is_blank <- function (x)
{
  if (length(x))
    all(grepl("^\\s*$", x))
  else TRUE
}

trim_trailing_ws <- function (x) {
  sub("\\s+$", "", x)
}

# given a directory and a file, return a relative path from the directory to the
# file, or the unmodified file path if the file does not appear to be in the
# directory
relative_to <- function(dir, file) {
  # ensure directory ends with a /
  if (!identical(substr(dir, nchar(dir), nchar(dir)), "/")) {
    dir <- paste(dir, "/", sep="")
  }
  
  # if the file is prefixed with the directory, return a relative path
  if (identical(substr(file, 1, nchar(dir)), dir))
    file <- substr(file, nchar(dir) + 1, nchar(file))
  
  # simplify ./
  if (identical(substr(file, 1, 2), "./"))
    file <- substr(file, 3, nchar(file))
  
  file
}

# Find common base directory, throw error if it doesn't exist
base_dir <- function(x) {
  abs <- vapply(x, tools::file_path_as_absolute, character(1))
  
  base <- unique(dirname(abs))
  if (length(base) > 1) {
    stop("Input files not all in same directory, please supply explicit wd",
         call. = FALSE)
  }
  
  base
}
