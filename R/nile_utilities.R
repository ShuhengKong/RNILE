#' Initialize NILE with default dictionaries
#' 
#' @description Creates and initializes a NILE processor with the default dictionaries
#' @return Java NLP object ready for use
#' @export
#' @examples
#' \dontrun{
#' nlp <- init_nile()
#' }
init_nile <- function() {
  nlp <- new_nlp()
  
  # Load default dictionaries from package
  dict_obs <- system.file("java", "dict_obs.txt", package = "RNILE")
  dict_loc <- system.file("java", "dict_locations.txt", package = "RNILE")
  dict_mod <- system.file("java", "dict_modifiers.txt", package = "RNILE")
  dict_mdd <- system.file("java", "MDD_dict.txt", package = "RNILE")
  
  # Add vocabularies
  if (file.exists(dict_obs)) {
    add_vocabulary(nlp, dict_obs, "OBSERVATION")
  }
  if (file.exists(dict_loc)) {
    add_vocabulary(nlp, dict_loc, "LOCATION")
  }
  if (file.exists(dict_mod)) {
    add_vocabulary(nlp, dict_mod, "MODIFIER")
  }
  
  # Load MDD dictionary phrase by phrase to handle conflicts
  if (file.exists(dict_mdd)) {
    load_mdd_dictionary(nlp, dict_mdd)
  }
  
  return(nlp)
}

#' Load MDD dictionary safely
#' 
#' @description Loads the MDD dictionary phrase by phrase, skipping conflicts
#' @param nlp Java NLP object
#' @param dict_file character path to MDD dictionary file
#' @return logical indicating completion
load_mdd_dictionary <- function(nlp, dict_file) {
  if (!file.exists(dict_file)) {
    warning("MDD dictionary file not found: ", dict_file)
    return(FALSE)
  }
  
  lines <- readLines(dict_file, warn = FALSE)
  success_count <- 0
  error_count <- 0
  
  for (line in lines) {
    # Skip comments and empty lines
    line <- strsplit(line, "//")[[1]][1]
    line <- trimws(line)
    if (line == "") next
    
    # Parse term|code format
    parts <- strsplit(line, "\\|")[[1]]
    if (length(parts) >= 2) {
      term <- trimws(tolower(parts[1]))
      code <- trimws(toupper(parts[2]))
    } else {
      term <- trimws(tolower(parts[1]))
      code <- trimws(toupper(parts[1]))
    }
    
    # Try to add the phrase
    if (add_phrase(nlp, term, code, "OBSERVATION")) {
      success_count <- success_count + 1
    } else {
      error_count <- error_count + 1
    }
  }
  
  message("MDD dictionary loaded: ", success_count, " terms added, ", 
          error_count, " conflicts skipped")
  return(TRUE)
}

#' Process text and return R data frame
#' 
#' @description Processes text and returns results in a convenient R data frame format
#' @param nlp Java NLP object
#' @param text character(1) the text to process
#' @return data.frame with columns: sentence_id, entity_text, codes, semantic_role, certainty, family_history
#' @export
#' @examples
#' \dontrun{
#' nlp <- init_nile()
#' result <- process_text(nlp, "No filling defects suggesting pulmonary embolism.")
#' print(result)
#' }
process_text <- function(nlp, text) {
  sentences <- dig_text_line(nlp, text)
  
  results <- list()
  
  for (i in seq_along(sentences)) {
    sentence <- sentences[[i]]
    semantic_objs <- get_semantic_objects(sentence)
    
    if (length(semantic_objs) > 0) {
      for (j in seq_along(semantic_objs)) {
        obj <- semantic_objs[[j]]
        
        result_row <- data.frame(
          sentence_id = i,
          entity_text = get_text(obj),
          codes = paste(get_codes(obj), collapse = "; "),
          semantic_role = get_semantic_role(obj),
          certainty = get_certainty(obj),
          family_history = is_family_history(obj),
          stringsAsFactors = FALSE
        )
        
        results[[length(results) + 1]] <- result_row
      }
    }
  }
  
  if (length(results) > 0) {
    return(do.call(rbind, results))
  } else {
    return(data.frame(
      sentence_id = integer(0),
      entity_text = character(0),
      codes = character(0),
      semantic_role = character(0),
      certainty = character(0),
      family_history = logical(0),
      stringsAsFactors = FALSE
    ))
  }
}

#' Print semantic object details recursively
#' 
#' @description Prints detailed information about a semantic object and its modifiers
#' @param semantic_obj Java SemanticObject
#' @param indent integer indentation level
#' @export
print_semantic_object <- function(semantic_obj, indent = 0) {
  prefix <- paste(rep("  ", indent), collapse = "")
  
  cat(prefix, "Text: ", get_text(semantic_obj), "\n")
  cat(prefix, "Codes: ", paste(get_codes(semantic_obj), collapse = ", "), "\n")
  cat(prefix, "Role: ", get_semantic_role(semantic_obj), "\n")
  cat(prefix, "Certainty: ", get_certainty(semantic_obj), "\n")
  cat(prefix, "Family History: ", is_family_history(semantic_obj), "\n")
  
  modifiers <- get_modifiers(semantic_obj)
  if (length(modifiers) > 0) {
    cat(prefix, "Modifiers:\n")
    for (modifier in modifiers) {
      print_semantic_object(modifier, indent + 1)
    }
  }
}

#' Get available Java classes and methods
#' 
#' @description Helper function to inspect the Java classes available in NILE
#' @return character vector of class information
#' @export
inspect_nile_classes <- function() {
  cat("NILE Java Classes Available:\n")
  cat("============================\n\n")
  
  cat("NaturalLanguageProcessor methods:\n")
  print(rJava::.jmethods("edu.harvard.hsph.biostats.nile.NaturalLanguageProcessor"))
  
  cat("\nSemanticObject methods:\n")
  print(rJava::.jmethods("edu.harvard.hsph.biostats.nile.SemanticObject"))
  
  cat("\nSentence methods:\n")
  print(rJava::.jmethods("edu.harvard.hsph.biostats.nile.Sentence"))
  
  cat("\nSemanticRole enum values:\n")
  print(rJava::.jfields("edu.harvard.hsph.biostats.nile.SemanticRole"))
}

#' Inspect Available Java Methods
#' 
#' Inspect the available Java methods in the NILE package
#' 
#' @return List of available Java methods
#' @export
inspect_java_methods <- function() {
  tryCatch({
    cat("Available Java Methods in NILE:\n")
    cat("===============================\n\n")
    
    # Get methods for main NILE classes
    cat("NaturalLanguageProcessor methods:\n")
    nlp_methods <- rJava::.jmethods("edu.harvard.hsph.biostats.nile.NaturalLanguageProcessor")
    print(nlp_methods)
    
    cat("\nSemanticObject methods:\n")
    sem_methods <- rJava::.jmethods("edu.harvard.hsph.biostats.nile.SemanticObject")
    print(sem_methods)
    
    return(invisible(list(nlp = nlp_methods, semantic = sem_methods)))
  }, error = function(e) {
    cat("Error inspecting Java methods:", e$message, "\n")
    cat("Make sure NILE.jar is loaded and JVM is initialized.\n")
    return(NULL)
  })
}

#' Run NILE Example
#' 
#' Run a basic example demonstrating NILE functionality
#' 
#' @return Example results
#' @export
run_nile_example <- function() {
  cat("Running NILE Example...\n")
  cat("========================\n\n")
  
  tryCatch({
    # Initialize NILE
    nlp <- init_nile()
    cat("✓ NILE initialized successfully\n\n")
    
    # Example text
    example_text <- "Patient has pneumonia in the right lung. No evidence of pulmonary embolism."
    cat("Example text:", example_text, "\n\n")
    
    # Process the text
    cat("Processing text...\n")
    result <- process_text(nlp, example_text)
    cat("✓ Text processed successfully\n")
    cat("Found", nrow(result), "semantic entities\n\n")
    
    # Show results
    if (nrow(result) > 0) {
      cat("Extracted entities:\n")
      print(result)
    }
    
    # Test sentence analysis
    cat("\nAnalyzing sentences...\n")
    sentences <- dig_text_line(nlp, example_text)
    cat("✓ Sentence analysis complete\n")
    cat("Processed", length(sentences), "sentences\n\n")
    
    cat("✓ NILE example completed successfully!\n")
    return(invisible(list(entities = result, sentences = sentences)))
    
  }, error = function(e) {
    cat("✗ Error in NILE example:", e$message, "\n")
    cat("Please check your NILE installation and Java setup.\n")
    return(NULL)
  })
} 