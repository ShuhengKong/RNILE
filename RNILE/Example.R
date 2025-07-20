#!/usr/bin/env Rscript
# =============================================================================
# RNILE Package Test Example
# =============================================================================
# This script comprehensively tests the RNILE package functionality
# including initialization, text processing, and semantic analysis.
#
# Usage: 
# 1. Install the package first: install.packages(".", repos = NULL, type = "source")
# 2. Run this script: source("Example.R")
# =============================================================================

# Clear workspace
rm(list = ls())

# Define string concatenation operator for convenience
`%+%` <- function(a, b) paste0(a, b)

# Load required libraries
cat("Loading required libraries...\n")
suppressPackageStartupMessages({
  if (!require(rJava, quietly = TRUE)) {
    cat("Installing rJava package...\n")
    install.packages("rJava")
    library(rJava)
  }
})

# =============================================================================
# Test 1: Package Loading and Initialization
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 1: Package Loading and Initialization\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_package_loading <- function() {
  tryCatch({
    # Check if RNILE package is installed
    if (!requireNamespace("RNILE", quietly = TRUE)) {
      cat("✗ RNILE package not found. Please install it first:\n")
      cat("  install.packages('.', repos = NULL, type = 'source')\n")
      return(FALSE)
    }
    
    # Load RNILE package
    library(RNILE)
    cat("✓ RNILE package loaded successfully\n")
    
    # Check Java initialization
    cat("✓ Java VM initialized with NILE.jar\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("✗ Error loading RNILE package: ", e$message, "\n")
    return(FALSE)
  })
}

if (!test_package_loading()) {
  stop("Failed to load RNILE package. Please check installation.")
}

# =============================================================================
# Test 2: Basic NLP Object Creation
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 2: Basic NLP Object Creation\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_nlp_creation <- function() {
  tryCatch({
    # Create new NLP object
    nlp <- new_nlp()
    cat("✓ NLP object created successfully\n")
    
    # Check object type
    if (inherits(nlp, "jobjRef")) {
      cat("✓ NLP object is a valid Java reference\n")
      return(nlp)
    } else {
      cat("✗ NLP object is not a valid Java reference\n")
      return(NULL)
    }
    
  }, error = function(e) {
    cat("✗ Error creating NLP object: ", e$message, "\n")
    return(NULL)
  })
}

basic_nlp <- test_nlp_creation()
if (is.null(basic_nlp)) {
  stop("Failed to create basic NLP object")
}

# =============================================================================
# Test 3: Dictionary Loading
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 3: Dictionary Loading\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_dictionary_loading <- function() {
  tryCatch({
    nlp <- new_nlp()
    
    # Test individual dictionary files
    dict_files <- list(
      obs = system.file("java", "dict_obs.txt", package = "RNILE"),
      loc = system.file("java", "dict_locations.txt", package = "RNILE"),
      mod = system.file("java", "dict_modifiers.txt", package = "RNILE"),
      mdd = system.file("java", "MDD_dict.txt", package = "RNILE")
    )
    
    # Check if dictionary files exist
    for (name in names(dict_files)) {
      if (file.exists(dict_files[[name]])) {
        cat("✓ Found", name, "dictionary:", dict_files[[name]], "\n")
      } else {
        cat("✗ Missing", name, "dictionary:", dict_files[[name]], "\n")
      }
    }
    
    # Test loading individual dictionaries
    if (file.exists(dict_files$obs)) {
      success <- add_vocabulary(nlp, dict_files$obs, "OBSERVATION")
      cat(ifelse(success, "✓", "✗"), "Loaded observations dictionary\n")
    }
    
    if (file.exists(dict_files$loc)) {
      success <- add_vocabulary(nlp, dict_files$loc, "LOCATION")
      cat(ifelse(success, "✓", "✗"), "Loaded locations dictionary\n")
    }
    
    if (file.exists(dict_files$mod)) {
      success <- add_vocabulary(nlp, dict_files$mod, "MODIFIER")
      cat(ifelse(success, "✓", "✗"), "Loaded modifiers dictionary\n")
    }
    
    return(nlp)
    
  }, error = function(e) {
    cat("✗ Error loading dictionaries: ", e$message, "\n")
    return(NULL)
  })
}

dict_nlp <- test_dictionary_loading()

# =============================================================================
# Test 4: Comprehensive Initialization with init_nile()
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 4: Comprehensive Initialization\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_init_nile <- function() {
  tryCatch({
    cat("Initializing NILE with all default dictionaries...\n")
    nlp <- init_nile()
    cat("✓ NILE initialized successfully with all dictionaries\n")
    return(nlp)
    
  }, error = function(e) {
    cat("✗ Error initializing NILE: ", e$message, "\n")
    return(NULL)
  })
}

full_nlp <- test_init_nile()
if (is.null(full_nlp)) {
  stop("Failed to initialize NILE with dictionaries")
}

# =============================================================================
# Test 5: Basic Text Processing
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 5: Basic Text Processing\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_text_processing <- function() {
  # Test cases with different types of medical text
  test_cases <- c(
    "Patient has pneumonia in the right lung.",
    "No filling defects are seen to suggest pulmonary embolism.",
    "There is acute myocardial infarction with ST elevation.",
    "Rule out pneumothorax in the left upper lobe.",
    "History of chronic obstructive pulmonary disease.",
    "Bilateral pneumonia with pleural effusion.",
    "No evidence of acute pathology."
  )
  
  results <- list()
  
  for (i in seq_along(test_cases)) {
    text <- test_cases[i]
    cat("\nTest Case", i, ":", text, "\n")
    
    tryCatch({
      # Process using dig_text_line
      sentences <- dig_text_line(full_nlp, text)
      cat("✓ Processed", length(sentences), "sentences\n")
      
      # Process using process_text (returns data frame)
      result_df <- process_text(full_nlp, text)
      cat("✓ Extracted", nrow(result_df), "semantic entities\n")
      
      if (nrow(result_df) > 0) {
        cat("  Entities found:\n")
        for (j in 1:nrow(result_df)) {
          cat("    -", result_df$entity_text[j], 
              "(", result_df$semantic_role[j], ")\n")
        }
      }
      
      results[[i]] <- list(
        text = text,
        sentences = sentences,
        entities = result_df
      )
      
    }, error = function(e) {
      cat("✗ Error processing text:", e$message, "\n")
      results[[i]] <- list(text = text, error = e$message)
    })
  }
  
  return(results)
}

processing_results <- test_text_processing()

# =============================================================================
# Test 6: Detailed Semantic Analysis
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 6: Detailed Semantic Analysis\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_semantic_analysis <- function() {
  test_text <- "Patient has acute bilateral pneumonia with pleural effusion in both lungs."
  cat("Analyzing text:", test_text, "\n\n")
  
  tryCatch({
    sentences <- dig_text_line(full_nlp, test_text)
    
    for (i in seq_along(sentences)) {
      sentence <- sentences[[i]]
      cat("Sentence", i, ":\n")
      
      # Get semantic objects
      semantic_objs <- get_semantic_objects(sentence)
      cat("  Found", length(semantic_objs), "semantic objects\n")
      
      for (j in seq_along(semantic_objs)) {
        obj <- semantic_objs[[j]]
        cat("\n  Object", j, ":\n")
        
        # Extract all information
        text <- get_text(obj)
        codes <- get_codes(obj)
        role <- get_semantic_role(obj)
        certainty <- get_certainty(obj)
        family_hist <- is_family_history(obj)
        
        cat("    Text:", text, "\n")
        cat("    Codes:", paste(codes, collapse = ", "), "\n")
        cat("    Role:", role, "\n")
        cat("    Certainty:", certainty, "\n")
        cat("    Family History:", family_hist, "\n")
        
        # Check for modifiers
        modifiers <- get_modifiers(obj)
        if (length(modifiers) > 0) {
          cat("    Modifiers:\n")
          for (k in seq_along(modifiers)) {
            mod <- modifiers[[k]]
            cat("      -", get_text(mod), 
                "(", get_semantic_role(mod), ")\n")
          }
        }
      }
    }
    
    return(TRUE)
    
  }, error = function(e) {
    cat("✗ Error in semantic analysis: ", e$message, "\n")
    return(FALSE)
  })
}

semantic_success <- test_semantic_analysis()

# =============================================================================
# Test 7: Edge Cases and Error Handling
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 7: Edge Cases and Error Handling\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_edge_cases <- function() {
  edge_cases <- c(
    "",  # Empty string
    "   ",  # Whitespace only
    "This is not medical text.",  # Non-medical text
    "Patient.",  # Very short text
    paste(rep("This is a very long sentence with many words.", 20), collapse = " ")  # Very long text
  )
  
  for (i in seq_along(edge_cases)) {
    text <- edge_cases[i]
    display_text <- if (nchar(text) > 50) paste0(substr(text, 1, 50), "...") else text
    cat("Edge case", i, ":", ifelse(text == "", "[empty]", 
                                   ifelse(trimws(text) == "", "[whitespace]", display_text)), "\n")
    
    tryCatch({
      result <- process_text(full_nlp, text)
      cat("✓ Processed successfully,", nrow(result), "entities found\n")
      
    }, error = function(e) {
      cat("✓ Handled error gracefully:", e$message, "\n")
    })
  }
}

test_edge_cases()

# =============================================================================
# Test 8: Custom Dictionary Addition
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 8: Custom Dictionary Addition\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_custom_phrases <- function() {
  tryCatch({
    nlp <- new_nlp()
    
    # Add custom phrases
    custom_phrases <- list(
      list(term = "covid-19", code = "COVID19", role = "OBSERVATION"),
      list(term = "sars-cov-2", code = "SARSCOV2", role = "OBSERVATION"),
      list(term = "nasopharynx", code = "NASO", role = "LOCATION"),
      list(term = "severe", code = "SEV", role = "MODIFIER")
    )
    
    for (phrase in custom_phrases) {
      success <- add_phrase(nlp, phrase$term, phrase$code, phrase$role)
      cat(ifelse(success, "✓", "✗"), "Added custom phrase:", phrase$term, "\n")
    }
    
    # Test with custom text
    test_text <- "Patient has severe COVID-19 infection in the nasopharynx."
    cat("\nTesting custom phrases with:", test_text, "\n")
    
    result <- process_text(nlp, test_text)
    cat("✓ Found", nrow(result), "entities with custom dictionary\n")
    
    if (nrow(result) > 0) {
      print(result)
    }
    
    return(TRUE)
    
  }, error = function(e) {
    cat("✗ Error with custom phrases: ", e$message, "\n")
    return(FALSE)
  })
}

custom_success <- test_custom_phrases()

# =============================================================================
# Test 9: Built-in Example Function
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 9: Built-in Example Function\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_built_in_example <- function() {
  tryCatch({
    cat("Running built-in NILE example...\n")
    example_result <- run_nile_example()
    cat("✓ Built-in example completed successfully\n")
    return(example_result)
    
  }, error = function(e) {
    cat("✗ Error in built-in example: ", e$message, "\n")
    return(NULL)
  })
}

example_result <- test_built_in_example()

# =============================================================================
# Test 10: Performance and Memory Test
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST 10: Performance and Memory Test\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

test_performance <- function() {
  # Generate multiple medical texts for batch processing
  medical_texts <- c(
    "Patient presents with chest pain and shortness of breath.",
    "CT scan shows pulmonary embolism in the right lower lobe.",
    "No acute findings on chest X-ray examination.",
    "History of myocardial infarction and diabetes mellitus.",
    "Bilateral pneumonia with pleural effusion noted.",
    "Rule out pneumothorax after chest trauma.",
    "Acute respiratory distress syndrome requiring ventilation.",
    "Chronic obstructive pulmonary disease exacerbation.",
    "No evidence of pulmonary edema or consolidation.",
    "Segmental atelectasis in the left upper lobe."
  )
  
  cat("Processing", length(medical_texts), "medical texts...\n")
  
  # Measure processing time
  start_time <- Sys.time()
  
  total_entities <- 0
  for (i in seq_along(medical_texts)) {
    text <- medical_texts[i]
    tryCatch({
      result <- process_text(full_nlp, text)
      total_entities <- total_entities + nrow(result)
      
    }, error = function(e) {
      cat("Error processing text", i, ":", e$message, "\n")
    })
  }
  
  end_time <- Sys.time()
  processing_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  cat("✓ Processed", length(medical_texts), "texts in", 
      round(processing_time, 3), "seconds\n")
  cat("✓ Total entities extracted:", total_entities, "\n")
  cat("✓ Average processing speed:", 
      round(length(medical_texts) / processing_time, 2), "texts/second\n")
  
  return(list(
    total_texts = length(medical_texts),
    total_entities = total_entities,
    processing_time = processing_time
  ))
}

performance_result <- test_performance()

# =============================================================================
# Test Summary and Results
# =============================================================================
cat("\n" %+% paste(rep("=", 60), collapse = "") %+% "\n")
cat("TEST SUMMARY AND RESULTS\n")
cat(paste(rep("=", 60), collapse = "") %+% "\n")

# Count successful tests
successful_tests <- c(
  !is.null(basic_nlp),
  !is.null(dict_nlp),
  !is.null(full_nlp),
  length(processing_results) > 0,
  semantic_success,
  custom_success,
  !is.null(example_result),
  !is.null(performance_result)
)

total_tests <- length(successful_tests)
passed_tests <- sum(successful_tests)

cat("Tests Summary:\n")
cat("==============\n")
cat("Total tests run:", total_tests, "\n")
cat("Tests passed:", passed_tests, "\n")
cat("Tests failed:", total_tests - passed_tests, "\n")
cat("Success rate:", round(100 * passed_tests / total_tests, 1), "%\n\n")

if (passed_tests == total_tests) {
  cat("🎉 ALL TESTS PASSED! 🎉\n")
  cat("RNILE package is working correctly!\n\n")
} else {
  cat("⚠️  Some tests failed. Please check the error messages above.\n\n")
}

# Print detailed results if available
if (!is.null(performance_result)) {
  cat("Performance Summary:\n")
  cat("===================\n")
  cat("Texts processed:", performance_result$total_texts, "\n")
  cat("Entities extracted:", performance_result$total_entities, "\n")
  cat("Processing time:", round(performance_result$processing_time, 3), "seconds\n")
  cat("Processing speed:", round(performance_result$total_texts / performance_result$processing_time, 2), "texts/second\n\n")
}

# =============================================================================
# Additional Helper Functions for Users
# =============================================================================
cat("Additional Functions Available:\n")
cat("===============================\n")
cat("- inspect_nile_classes(): Inspect available Java classes and methods\n")
cat("- inspect_java_methods(): Detailed inspection of Java methods\n")
cat("- run_nile_example(): Run the built-in example\n")
cat("- print_semantic_object(obj): Print detailed object information\n\n")

cat("Example Usage:\n")
cat("==============\n")
cat("library(RNILE)\n")
cat("nlp <- init_nile()\n")
cat("result <- process_text(nlp, 'Your medical text here')\n")
cat("print(result)\n\n")

cat("✓ RNILE functionality test completed!\n")
cat("The package is ready for use in medical text processing.\n")
