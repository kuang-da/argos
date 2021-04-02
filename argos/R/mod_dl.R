# Helper function ----------------

# UI function ----------------

dataLoaderUI <- function(id) {
  ns <- NS(id)
  tabItem(tabName = "data_upload",
          
          tabsetPanel(
            tabPanel(
              "Upload dataset",
              fluidPage(
                fluidRow(wellPanel(
                  shinyFiles::shinyDirButton(
                    ns("folder"),
                    "Select a folder",
                    "Please select a folder",
                    FALSE,
                    class = "btn-success"
                  )
                )),
                
                fluidRow(wellPanel(verbatimTextOutput(
                  ns("dataset_path_log")
                ))),
                
                fluidRow(wellPanel(
                  actionButton(ns("load_data_button"),
                               "Upload Data",
                               class = "btn-primary")
                )),
                
                fluidRow(wellPanel(verbatimTextOutput(ns(
                  "upload_log"
                ))))
              )
            ),
            tabPanel("Design Table", 
                     DTOutput(ns('designTable'))),
            tabPanel("Dimension Reduction", 
                     dlDimensionReductionUI(ns("dimensionReduction")))
          ))
}

# Server function ----------------
# Return: list(rawData, normData, colData)
dataLoaderSever <- function(id) {
  moduleServer(id, function(input, output, session) {
    ###############################
    # Define Output
    ###############################
    dataset <- reactiveValues(
      rawData = NULL,
      normData = NULL,
      colData = NULL,
      geneUniverse = NULL,
      title = NULL
    )
    
    ###############################
    # Select dataset Folder
    ###############################
    roots <- c(wd = '.')
    
    shinyDirChoose(input,
                   "folder",
                   roots = roots,
                   filetypes = c("", "txt"))
    
    datasetPath <- reactive({
      parseDirPath(roots, input$folder)
    })
    
    observe({
      if (length(input$folder) <= 1) {
        dataset$title <- reactive({
          "Argos"
        })
      } else{
        dataset$title <-
          reactive({
            paste0("Argos-", input$folder[["path"]][[3]])
          })
      }
    })
    
    ###############################
    # Generate Reading Log
    ###############################
    # Default
    observe({
      req(length(input$folder) <= 1)
      output$dataset_path_log <- renderText({
        INFO_STR
      })
    })
    # Reading Log
    observe({
      req(length(input$folder) > 1)
      print("Updating file path log...")
      output$dataset_path_log <- renderText({
        paste0("Selected Path of the dataset:\n",
               datasetPath())
      })
    })
    
    observeEvent(input$load_data_button, {
      req(datasetPath)
      print("Loading rawData...")
      str <- ""
      str <- paste0(str, "Loding count matrix...\n")
      dataset$rawData <-
        reactive(load_dataset(file.path(datasetPath(), "count-matrix.csv")))
      
      str <- paste0(str, "Loding Normalized count matrix...\n")
      dataset$normData <-
        reactive(load_dataset(file.path(
          datasetPath(), "count-matrix-norm.csv"
        )))
      
      str <- paste0(str, "Loding Column Data...\n")
      dataset$colData <-
        reactive(load_coldata(file.path(datasetPath(), "design-table.csv")))
      
      str <-
        paste0(str, "Extracting Gene Symbols from the Data...\n")
      dataset$geneUniverse <- reactive(rownames(dataset$rawData()))
      
      str <- paste0(str, "Done!\n")
      output$upload_log <- renderText({
        str
      })
      
    })
    
    ###############################
    # Design Table
    ###############################
    observe({
      req(dataset$colData)
      req(dataset$colData())
      
      output$designTable <- renderDT(
        dataset$colData() %>% dplyr::count(Group)
      )
    })
    
    
    # Dimension Reduction ------------------
    observe({
      req(dataset)
      req(dataset$colData)
      req(dataset$colData())
      dlDimensionReductionServer("dimensionReduction", dataset)
    })
    ###############################
    # Output
    ###############################
    dataset
  })
}