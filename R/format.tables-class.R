#' format.tables class
#' 
#' @description Class for format.tables
#' 
#' 
#' @param data data frame, argument used to initialise class
#' @param styles character vector with styles , argument used to initialise class
#' @param column.names column names of the data , argument used to initialise class
#' @param names.style style for the column names, argument used to initialise class
#' @param header list of key, value for header information, e.g. caption, subcaption, width etc. , argument used to initialise class
#' @param names.note note for the column names, argument used to initialise class
#' @param notes notes for the data, argument used to initialise class
#' @param file the name of the file which the data are to be read from
#' @param ... arguments passed to \code{\link[format.tables:read]{read}}
#' 
#' @import whisker
#' @import methods
#' @import yaml
#' @aliases format.tables format.table
#' 
#' @export
format.tables <- setRefClass(
  "format.tables",
  fields = list(
    data = "ANY",
    styles = "character",
    
    column.names = "ANY",
    names.style = "ANY", 
    
    header = "ANY",
    
    names.note = "ANY", 
    notes = "ANY"
        
  ),
  methods = list(
    initialize = function(data = NULL, 
                          styles, 
                          column.names = names(data), 
                          names.style, 
                          header, 
                          names.note = NULL, 
                          notes = NULL, 
                          file = NULL, 
                          ...) {
      
      if (!is.null(file)) {
        read(file, ...)
      } else {
        
        # change to functions with tests
        .self$data <- data
        .self$styles <- styles
        
        .self$column.names <- column.names
        .self$names.style <- names.style
        
        .self$header <- header
        
        .self$names.note <- names.note
        .self$notes <- notes
        
        
      }
      
      sanitize()
      
      
      
    }, 
    sanitize = function(){
      if (!is.data.frame(.self$data)) {
        stop("Only data.frame or data.table are supported")
      }
      if (!is.null(.self$names.note) && class(.self$names.note) != "character") {
        stop("names.note must be either NULL or of class character. The input was of class ", class(.self$names.note), ".")
      }
      if (!is.null(.self$notes) && class(.self$notes) != "character") {
        stop("notes must be either NULL or of class character. The input was of class ", class(.self$notes), ".")
      }
      if (!is.null(.self$header) && class(.self$header) != "list") {
        stop("invalid assignment for reference class field \"header\", should be from class \u201clist\u201d or a subclass (was class '", class(header), "')")
      }
      if (!is.null(.self$column.names) && class(.self$column.names) != "character") {
        stop("invalid assignment for reference class field \"column.names\", should be from class \u201ccharacter\u201d or a subclass (was class '", class(.self$column.names), "')")
      }
      if (!is.null(.self$names.style) && class(.self$names.style) != "character") {
        stop("invalid assignment for reference class field \"names.style\", should be from class \u201ccharacter\u201d or a subclass (was class '", class(.self$names.style), "')")
      }
      
      if (nrow(.self$data) != length(.self$styles)) {
        stop("'data' and 'style' must have the same row count/length")
      }
      if (!is.null(.self$column.names) && ncol(.self$data) != length(.self$column.names)) {
        stop("'data' and 'column.names' must have the same column count/length")
      }
      if (!is.null(.self$column.names) & is.null(.self$names.style)) {
        stop("if you provide 'column.names' you must also provide 'names.style'")
      }
      
      if (!is.null(.self$notes) && nrow(.self$data) != length(.self$notes)) {
        stop("'data' and 'notes' must have the same row count/length")
      }
      
      if (is.null(.self$column.names) & !is.null(.self$names.style)) {
        warning("you provided 'names.style' but no 'column.names', 'names.style' will be discarded")
        .self$names.style <- NULL
      }
      if (!is.null(.self$notes) & !is.null(.self$column.names) & is.null(.self$names.note)) {
        warning("you provided 'notes' and 'column.names' but no 'names.note'. 'names.note' will be set to an empty character string.")
        .self$names.note <- ""
      }
      if (is.null(.self$notes) & !is.null(.self$names.note)) {
        warning("you provided 'names.note' but no 'notes', 'names.note' will be discarded")
        .self$names.note <- NULL
      }
    },
    print = function(type, template = ""){
      base::print(type)
    }, 
    write = function(file = "", dec = ft.opts.get("dec", "write", "."), sep = ft.opts.get("sep", "write", ","), ...){
      sanitize()
      
      export.data <- .self$data
      
      # change decimal mark for converting numeric to character
      OutDec <- getOption("OutDec")
      options(OutDec = dec)
      
      # convert numeric to character, as.character is used as it is more convenient than format or formatC
      for (i in 1:ncol(export.data)) {
        if (class(export.data[[i]]) != "character" & typeof(export.data[[i]]) != "character") {
          export.data[[i]] <- as.character(export.data[[i]]) 
        }
      }
      
      # restore OutDec option
      options(OutDec = OutDec)
      
      #putting together styles, data, and notes
      .styles <- .self$styles
      .notes <- .self$notes
      if (!is.null(.self$names.style)) {
        .styles <- c(.self$names.style, .styles)
        if (!is.null(.notes)) 
          .notes <- c(ifelse(is.null(.self$names.note), NA, .self$names.note), .notes)
        export.data <- rbind(.self$column.names, export.data)
      } 
      .styles <- c("styles", .styles)
      
      export.data <- rbind(rep(NA, ncol(export.data)), export.data)
      
      export.data <- cbind(.styles, export.data, stringsAsFactors = FALSE)
      
      if (!is.null(.notes)) 
        export.data <- cbind(export.data, c("notes", .notes), stringsAsFactors = FALSE)
      

      .header <- data.frame(keys = names(.self$header), 
                            values = unlist(.self$header), 
                            stringsAsFactors = FALSE)

      # adding columns to fit the width of the data
      export.header <- cbind(.header, 
                             matrix(rep(NA, (ncol(export.data)-ncol(.header))*nrow(.header)), 
                                    ncol =  ncol(export.data)-ncol(.header) 
                             ), 
                             stringsAsFactors = FALSE
                             )
      names(export.data) <- names(export.header)
      
      export.data <- rbind(export.header, rep(NA, ncol(export.header)), export.data)
      
      names(export.data) <- paste0("V", 1:ncol(export.data))
      row.names(export.data) <- 1:nrow(export.data)
      
      if (file == "") {
        print(export.data)
      } else {
        ft.opts.write <- ft.opts.get("write", domain = NULL, default = NULL)
        if (is.null(ft.opts.write))
          ft.opts.write <- list()
        
        do.call.merge.args(FUN=write.table, 
                           ft.opts.write, 
                           list(x = export.data, 
                                file = file, 
                                na = "", 
                                sep = sep, 
                                row.names = FALSE, 
                                col.names = FALSE), 
                           list(...))
      }
      
    }, 
    
    #' see read.R for documentation
    read = function(file, 
                    has.column.names = ft.opts.get("has.column.names", "read", TRUE), 
                    convert.data = ft.opts.get("convert.data", "read", TRUE), 
                    dec = ft.opts.get("dec", "read", "."), 
                    sep = ft.opts.get("sep", "read", ","),
                    na.strings = ft.opts.get("na.strings", "read", "NA"), 
                    ...){
      
      # initialize variables 
      .header <- NULL
      .notes <- NULL
      .column.names <- NULL
      .names.style <- NULL
      .names.note <- NULL
      
      # blanks are also treated as NAs
      na.strings <- c("", na.strings)
      
      ft.opts.read <- ft.opts.get("read", domain = NULL, default = NULL)
      if (is.null(ft.opts.read))
        ft.opts.read <- list()
      
      # read from file
      raw <- do.call.merge.args(FUN=read.table, 
                                ft.opts.read, 
                                list(file = file, 
                                     dec = dec, 
                                     sep = sep, 
                                     na.strings = na.strings, 
                                     stringsAsFactors = FALSE, 
                                     colClasses = "character", 
                                     header = FALSE), 
                                list(...))
      
      # there has to be a line with only NAs between the header and the data
      if (sum(rowSums(is.na(raw)) == ncol(raw), na.rm = TRUE) > 0) {
        separation.index <- which.max(rowSums(is.na(raw)) == ncol(raw))
        
        # header: keys -> values 
        header.df <- raw[1:separation.index-1, c(1,2)]
        names(header.df) <- c("keys", "values")
        .header <- as.list(header.df$values)
        names(.header) <- header.df$keys
        
        # type convert header
        .header <- lapply(.header, function(x){
          do.call.merge.args(FUN = type.convert, list(x = x, dec = dec, as.is = TRUE))
        })
        
        # delete the header and keep just the data with styles and notes columns 
        raw <- raw[-(1:separation.index), ]
      }
      # styles 
      if (!isTRUE(raw[1, 1] == "styles"))
        stop("There is no style column in your data. Please add one and name it with 'styles'. ")

      .styles <- raw[2:nrow(raw), 1]
      raw[, 1] <- NULL
      
      # notes 
      if (isTRUE(raw[1, ncol(raw)] == "notes")) {
        .notes <- raw[2:nrow(raw), ncol(raw)]
        .notes[is.na(.notes)] <- ""
        raw[, ncol(raw)] <- NULL
      }
      
      
      # keep just the data, remove NA row (first row)
      raw <- raw[-1, ]
      # if raw is just one column it is converted to a vector, convert it back to a data frame
      if (!is.data.frame(raw)) 
        raw <- as.data.frame(raw, stringsAsFactors = FALSE)
      
      # column names
      if (has.column.names) {
        .column.names <- as.character(raw[1, ])
        .column.names[is.na(.column.names)] <- ""
        .names.style <- .styles[1]
        .styles <- .styles[-1]
        .names.note <- .notes[1]
        if(!is.null(.names.note)) .names.note[is.na(.names.note)] <- ""
        .notes <- .notes[-1]
        raw <- raw[-1, ]
      }
      
      # data
      .data <- raw
      
      if (!is.data.frame(.data))
        .data <- as.data.frame(.data, stringsAsFactors = FALSE)
      
      if (convert.data) {
        for (i in 1:ncol(.data)) {
          .data[[i]] <- type.convert(.data[[i]], dec = dec, as.is = TRUE)
        }
      }
      
      names(.data) <- paste0("V", 1:ncol(.data))
      
      .self$data <- .data
      .self$styles <- .styles
      .self$column.names <- .column.names
      .self$names.style <- .names.style
      .self$header <- .header
      .self$names.note <- .names.note
      .self$notes <- .notes
      
      
      
      # naming the notes with the number of the note respective
      # move this to add_notes function
      if (!is.null(.self$names.note) && .self$names.note != "")
        names(.self$names.note) <- "1"

      if (!is.null(.self$notes)) {
        offset <- 0
        if (!is.null(.self$names.note) && .self$names.note != "")
          offset <- 1
        
        names(.self$notes)[.self$notes != ""] <- (1+offset):(length(.self$notes[.self$notes != ""])+offset)
      }
      
    }, 
    
    #' see the file render.R for documentation 
    render = function(table.template = ft.opts.get("table.template", "render", NULL), 
                      row.template = ft.opts.get("row.template", "render", NULL), 
                      type = ft.opts.get("type", "render", "tex"),
                      collapse = ft.opts.get("collapse", "render", NULL),
                      format = ft.opts.get("format", "render", "f"),
                      digits = ft.opts.get("digits", "render", 0),
                      NA.string.formatted = ft.opts.get("NA.string.formatted", "render", ""),
                      NA.string.value = ft.opts.get("NA.string.value", "render", ""), 
                      ...){

      ft.opts.render <- ft.opts.get("render", domain = NULL, default = NULL)
      if (is.null(ft.opts.render))
        ft.opts.render <- list()
      
      # table id: can be used per row or in table template
      table.id <- .self$header$id
      if (is.null(table.id))
        table.id <- paste0("tbl_", paste(sample(letters, 8, replace=TRUE), collapse=""))      
      
      # type specific 
      collapse.tmp <- ""
      if (type == "tex") {
        if (is.null(table.template))
          table.template <- system.file("template", "ctable.whisker", package = getPackageName())
        if (is.null(row.template))
          row.template <- system.file("template", "tex.rows.yaml", package = getPackageName())
        collapse.tmp <- " & "
      } else if (type == "html") {
        if (is.null(table.template))
          table.template <- system.file("template", "html.whisker", package = getPackageName())
        if (is.null(row.template))
          row.template <- system.file("template", "html.rows.yaml", package = getPackageName())
        collapse.tmp <- ""
      } else if (type == "") {
        if(is.null(table.template) | is.null(row.template))
          stop("If you choose 'type = \"\"' you must provide both table.template and row.template.")
      } else {
        stop("'type' must be 'tex', 'html' or an empty string.")
      }
      
      if (is.null(collapse))
        collapse <- collapse.tmp
      
      # read table template
      table.template.whisker <- paste(readLines(table.template, warn = FALSE), collapse = "\n")
      
      # read row template
      rows.template <- paste0(readLines(row.template), collapse="\n")
      rows.template <- yaml.load(gsub("\\\\", "\\\\\\\\", rows.template))
      
      ##########
      # get delimiter for whisker: used for row template
      
      #' Split a character in three parts
      #'
      #' It differs from strsplit in that it only splits on the first occurrence
      #' and returns all parts of the string given
      #' @param x character text to be split
      #' @param pattern pattern used for splitting
      #' @keywords internal
      #' 
      #' Code borrowed from  Edwin de Jonge <edwindjonge@gmail.com> from the whisker-package
      rxsplit <- function(x, pattern){
        matched <- regexpr(pattern, x)
        if (matched == -1)
          return(x)
        ml <- attr(matched, "match.length")
        c( substring(x,1,matched-1)
           , substring(x,matched, matched+ml-1)
           , substring(x, matched + ml)
        )
      }
      
      delimtag <- "\\{\\{=\\s*(.+?)\\s*=\\}\\}"
      rx <- rxsplit(table.template.whisker, delimtag)

      whisker.delimiter <- unlist(strsplit(sub(delimtag, "\\1", rx[2]), " "))
      if (is.na(whisker.delimiter) || length(whisker.delimiter) == 0) 
        whisker.delimiter <- c("{{", "}}")
      
      # if the row template contains the element "whiskerSetDelimiter" use it as whisker delimiter
      if (!is.null(rows.template[["whiskerSetDelimiter"]]))
        whisker.delimiter <- unlist(strsplit(sub(delimtag, "\\1", rows.template[["whiskerSetDelimiter"]]), " "))
      
      whisker.delimiter.change <- ""
      if (whisker.delimiter[1] != "{{" | whisker.delimiter[2] != "}}") 
        whisker.delimiter.change <- paste0("{{=", whisker.delimiter[1], " ", whisker.delimiter[2], "=}}")
      
      
      ##########
      # get template for a specific row
      get_row_template <- function(style.name){
        tmp <- rows.template[[style.name]]
        if (!is.null(tmp)) {
          return(tmp)
        } else if (!is.null(rows.template[["default"]])) {
          return(rows.template[["default"]])
        } else {
          return(paste0(whisker.delimiter[1], "&value", whisker.delimiter[2]))
        }
      }
      
      ##########
      # should the rounding beeing overwritten? 
      if (!is.null(.self$header$digits) && is.character(.self$header$digits))
        digits <- as.numeric(strsplit(.self$header$digits, "\\|")[[1]])
      else if (!is.null(.self$header$digits))
        digits <- .self$header$digits
      
      # replicate digits and format to match ncol
      if (!is.null(digits))
        digits <- rep_len(digits, ncol(.self$data))
      format <- rep_len(format, ncol(.self$data))
      
      ##########
      # apply (whisker) template on all cells of one row
      apply_template_row <- function(template, data, note, format = NULL, digits = NULL, ...){
        formatted <- c()
        
        for (i in 1:length(data)) {
          if (class(data[[i]]) != "character") {
            formatted[i] <- do.call.merge.args(FUN = formatC, 
                               ft.opts.render, 
                               list(x = data[[i]], format = format[i], digits = digits[i]), 
                               list(...))
          } else {
            formatted[i] <- data[[i]]
          }
        }
        formatted <- unlist(formatted)
        if (any(is.na(unlist(data))))
          formatted[is.na(unlist(data))] <- NA.string.formatted
        
        row <- sapply(1:length(data), function(i){
          whisker.data <- list(ncol = length(data), value = ifelse(is.na(data[[i]]), NA.string.value, data[[i]]), formatted = formatted[i], colNumber = i, id = table.id)
          if (!is.null(note) && note != "")
            whisker.data <- c(whisker.data, list(noteNumber = names(note)))
          k <- ifelse(i > length(template), length(template), i)
          
          # get delimiter from template: first row
          whisker.render(paste0(whisker.delimiter.change, template[k]), whisker.data)
        })
        return(row)
      }
      
      ##########
      # column names
      if (!is.null(.self$column.names)) {
        tableRows.names <- list(list(tableRow = paste(apply_template_row(template = get_row_template(.self$names.style), 
                                                                         data = as.list(.self$column.names), 
                                                                         note = .self$names.note, 
                                                                         format = format, 
                                                                         digits = digits, 
                                                                         ...), 
                                                      collapse = collapse)
        ))
        if (!is.null(tableRows.names)) {
          tableRows.names[[1]][[.self$names.style]] <- TRUE
          tableRows.names[[1]][["style"]] <- .self$names.style
          tableRows.names[[1]][["id"]] <- table.id
        }
      }
      
      ##########
      # data rows
      tableRows.data <- as.list(sapply(1:nrow(.self$data), function(i, ...){
        row.list <- list(tableRow = paste(apply_template_row(template = get_row_template(.self$styles[i]), 
                                                             data = as.list(.self$data[i, ]), 
                                                             note = .self$notes[i],
                                                             format = format, 
                                                             digits = digits, 
                                                             ...)
                                          , collapse = collapse)
        )
        row.list[[.self$styles[i]]] <- TRUE
        row.list[["style"]] <- .self$styles[i]
        row.list[["id"]] <- table.id
        return(list(row.list))
      }, ...))
      
      # putting together column names and data rows
      if (!is.null(.self$column.names)) {
        tableRows = list(tableRows =  c(tableRows.names, tableRows.data))
      } else {
        tableRows = list(tableRows =  tableRows.data)
      }
      
      ##########
      # notes
      rowNotes <- NULL
      if (!is.null(.self$notes)) {
        .notes <- c(.self$names.note, .self$notes)
        .notes <- .notes[!is.na(.notes) & .notes != ""]
        names(.notes) <- 1:length(.notes)
        rowNotes <- list(rowNotes = iteratelist(.notes, name = "number", value = "note"))
        for (i in 1:length(rowNotes$rowNotes)) {
          rowNotes$rowNotes[[i]]$id <- table.id
        }
      }
      
      ##########
      # putting together data for whisker
      header.whisker <- c(.self$header, list(ncol = ncol(.self$data), id = table.id))

      whisker.data <- c(header.whisker, tableRows)
      if (!is.null(rowNotes))
        whisker.data <- c(whisker.data, rowNotes)
      
      return(whisker.render(table.template.whisker, data = whisker.data))
    }
  )
)
