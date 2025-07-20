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
#' @return data.frame with columns: sentence_id, entity_text, codes, semantic_role, certainty, family_history, offset_start, offset_end
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
          offset_start = get_offset_start(obj),
          offset_end = get_offset_end(obj),
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
      offset_start = integer(0),
      offset_end = integer(0),
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

#' Get detailed sentence analysis
#' 
#' @description Analyzes a sentence and returns detailed information including tokens
#' @param nlp Java NLP object
#' @param text character(1) the text to analyze
#' @return list with sentence information
#' @export
analyze_sentence <- function(nlp, text) {
  sentences <- dig_text_line(nlp, text)
  
  if (length(sentences) == 0) {
    return(list())
  }
  
  results <- list()
  for (i in seq_along(sentences)) {
    sentence <- sentences[[i]]
    
    sentence_info <- list(
      sentence_id = i,
      text = rJava::.jcall(sentence, "Ljava/lang/String;", "getText"),
      tokens = get_tokens(sentence),
      short_string = to_short_string(sentence),
      semantic_objects = get_semantic_objects(sentence)
    )
    
    results[[i]] <- sentence_info
  }
  
  return(results)
}

#' Extract hierarchical semantic information
#' 
#' @description Extracts semantic information preserving modifier relationships
#' @param nlp Java NLP object
#' @param text character(1) the text to process
#' @return nested list structure with modifiers
#' @export
extract_hierarchical_semantics <- function(nlp, text) {
  sentences <- dig_text_line(nlp, text)
  
  results <- list()
  
  for (i in seq_along(sentences)) {
    sentence <- sentences[[i]]
    semantic_objs <- get_semantic_objects(sentence)
    
    sentence_semantics <- list()
    
    for (j in seq_along(semantic_objs)) {
      obj <- semantic_objs[[j]]
      
      obj_info <- list(
        text = get_text(obj),
        codes = get_codes(obj),
        semantic_role = get_semantic_role(obj),
        certainty = get_certainty(obj),
        family_history = is_family_history(obj),
        offset_start = get_offset_start(obj),
        offset_end = get_offset_end(obj)
      )
      
      # Get modifiers recursively
      modifiers <- get_modifiers(obj)
      if (length(modifiers) > 0) {
        obj_info$modifiers <- list()
        for (k in seq_along(modifiers)) {
          mod <- modifiers[[k]]
          mod_info <- list(
            text = get_text(mod),
            codes = get_codes(mod),
            semantic_role = get_semantic_role(mod),
            certainty = get_certainty(mod),
            family_history = is_family_history(mod),
            offset_start = get_offset_start(mod),
            offset_end = get_offset_end(mod)
          )
          obj_info$modifiers[[k]] <- mod_info
        }
      }
      
      sentence_semantics[[j]] <- obj_info
    }
    
    results[[i]] <- list(
      sentence_id = i,
      sentence_text = rJava::.jcall(sentence, "Ljava/lang/String;", "getText"),
      semantics = sentence_semantics
    )
  }
  
  return(results)
}

#' Get all available semantic roles
#' 
#' @description Returns all possible semantic roles from the NILE system
#' @return character vector of semantic role names
#' @export
get_available_semantic_roles <- function() {
  tryCatch({
    # Get all semantic role enum values
    role_values <- rJava::.jcall("edu.harvard.hsph.biostats.nile.SemanticRole",
                                 "[Ledu/harvard/hsph/biostats/nile/SemanticRole;",
                                 "values")
    
    # Convert to character vector
    roles <- character(length(role_values))
    for (i in seq_along(role_values)) {
      roles[i] <- rJava::.jcall(role_values[[i]], "Ljava/lang/String;", "toString")
    }
    
    return(roles)
  }, error = function(e) {
    warning("Could not retrieve semantic roles: ", e$message)
    return(c("OBSERVATION", "LOCATION", "MODIFIER"))  # Fallback to main roles
  })
}

#' Get all available certainty levels
#' 
#' @description Returns all possible certainty levels from the NILE system
#' @return character vector of certainty level names
#' @export
get_available_certainty_levels <- function() {
  tryCatch({
    # Get all certainty enum values (class 'a' is the obfuscated Certainty enum)
    certainty_values <- rJava::.jcall("edu.harvard.hsph.biostats.nile.a",
                                      "[Ledu/harvard/hsph/biostats/nile/a;",
                                      "values")
    
    # Convert to character vector
    certainties <- character(length(certainty_values))
    for (i in seq_along(certainty_values)) {
      certainties[i] <- rJava::.jcall(certainty_values[[i]], "Ljava/lang/String;", "toString")
    }
    
    return(certainties)
  }, error = function(e) {
    warning("Could not retrieve certainty levels: ", e$message)
    return(c("YES", "NO", "UNCLEAR"))  # Fallback to known values
  })
}

#' Batch process multiple texts
#' 
#' @description Process multiple texts efficiently and return combined results
#' @param nlp Java NLP object
#' @param texts character vector of texts to process
#' @return data.frame with additional text_id column
#' @export
batch_process_texts <- function(nlp, texts) {
  all_results <- list()
  
  for (i in seq_along(texts)) {
    text <- texts[i]
    tryCatch({
      result <- process_text(nlp, text)
      if (nrow(result) > 0) {
        result$text_id <- i
        result$original_text <- text
        all_results[[length(all_results) + 1]] <- result
      }
    }, error = function(e) {
      warning("Error processing text ", i, ": ", e$message)
    })
  }
  
  if (length(all_results) > 0) {
    final_result <- do.call(rbind, all_results)
    # Reorder columns to put text_id first
    col_order <- c("text_id", "original_text", setdiff(names(final_result), c("text_id", "original_text")))
    return(final_result[, col_order])
  } else {
    return(data.frame())
  }
} 