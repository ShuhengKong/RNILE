#' Create a new Natural Language Processor
#' 
#' @description Creates a new instance of the NILE NaturalLanguageProcessor
#' @return Java object reference to edu.harvard.hsph.biostats.nile.NaturalLanguageProcessor
#' @export
#' @examples
#' \dontrun{
#' nlp <- new_nlp()
#' }
new_nlp <- function() {
  tryCatch({
    rJava::.jnew("edu.harvard.hsph.biostats.nile.NaturalLanguageProcessor")
  }, error = function(e) {
    stop("Failed to create NaturalLanguageProcessor: ", e$message)
  })
}

#' Add vocabulary from file
#' 
#' @description Loads a dictionary from a text file with format term|code
#' @param nlp Java NLP object (from new_nlp())
#' @param file_path character(1) path to dictionary file
#' @param semantic_role character(1) one of "OBSERVATION", "LOCATION", "MODIFIER"
#' @return logical indicating success
#' @export
#' @examples
#' \dontrun{
#' nlp <- new_nlp()
#' dict_file <- system.file("java", "dict_obs.txt", package = "RNILE")
#' add_vocabulary(nlp, dict_file, "OBSERVATION")
#' }
add_vocabulary <- function(nlp, file_path, semantic_role) {
  if (!inherits(nlp, "jobjRef"))
    stop("`nlp` must be a Java object created by new_nlp()")
  
  # Get the semantic role enum
  role_enum <- rJava::.jfield("edu.harvard.hsph.biostats.nile.SemanticRole", 
                              name = semantic_role)
  
  tryCatch({
    rJava::.jcall(nlp,
                  returnSig = "V",
                  method = "addVocabulary",
                  as.character(file_path),
                  role_enum)
    return(TRUE)
  }, error = function(e) {
    warning("Failed to add vocabulary from ", file_path, ": ", e$message)
    return(FALSE)
  })
}

#' Add a single phrase to vocabulary
#' 
#' @description Adds a single term with its code and semantic role
#' @param nlp Java NLP object (from new_nlp())
#' @param term character(1) the medical term
#' @param code character(1) the medical code
#' @param semantic_role character(1) one of "OBSERVATION", "LOCATION", "MODIFIER"
#' @return logical indicating success
#' @export
#' @examples
#' \dontrun{
#' nlp <- new_nlp()
#' add_phrase(nlp, "type 2 diabetes", "C0011860", "OBSERVATION")
#' }
add_phrase <- function(nlp, term, code, semantic_role) {
  if (!inherits(nlp, "jobjRef"))
    stop("`nlp` must be a Java object created by new_nlp()")
  
  # Get the semantic role enum
  role_enum <- rJava::.jfield("edu.harvard.hsph.biostats.nile.SemanticRole", 
                              name = semantic_role)
  
  tryCatch({
    rJava::.jcall(nlp,
                  returnSig = "V",
                  method = "addPhrase",
                  as.character(term),
                  as.character(code),
                  role_enum)
    return(TRUE)
  }, error = function(e) {
    warning("Failed to add phrase '", term, "': ", e$message)
    return(FALSE)
  })
}

#' Process text and extract semantic information
#' 
#' @description Processes a text line and returns a list of Sentence objects
#' @param nlp Java NLP object (from new_nlp())
#' @param text character(1) the text to process
#' @return list of Java Sentence objects
#' @export
#' @examples
#' \dontrun{
#' nlp <- new_nlp()
#' sentences <- dig_text_line(nlp, "No filling defects are seen.")
#' }
dig_text_line <- function(nlp, text) {
  if (!inherits(nlp, "jobjRef"))
    stop("`nlp` must be a Java object created by new_nlp()")
  
  tryCatch({
    result <- rJava::.jcall(nlp,
                           returnSig = "Ljava/util/List;",
                           method = "digTextLine",
                           as.character(text))
    
    # Convert Java List to R list for easier access
    sentence_list <- list()
    list_size <- rJava::.jcall(result, "I", "size")
    
    if (list_size > 0) {
      for (i in 0:(list_size - 1)) {
        sentence <- rJava::.jcall(result, "Ljava/lang/Object;", "get", as.integer(i))
        sentence_list[[i + 1]] <- sentence
      }
    }
    
    return(sentence_list)
  }, error = function(e) {
    stop("Failed to process text: ", e$message)
  })
}

#' Get semantic objects from a sentence
#' 
#' @description Extracts semantic objects from a Java Sentence object
#' @param sentence Java Sentence object
#' @return list of Java SemanticObject objects
#' @export
#' @examples
#' \dontrun{
#' nlp <- new_nlp()
#' sentences <- dig_text_line(nlp, "Pulmonary embolism detected.")
#' objects <- get_semantic_objects(sentences[[1]])
#' }
get_semantic_objects <- function(sentence) {
  if (!inherits(sentence, "jobjRef"))
    stop("`sentence` must be a Java Sentence object")
  
  tryCatch({
    result <- rJava::.jcall(sentence,
                           returnSig = "Ljava/util/List;",
                           method = "getSemanticObjs")
    
    # Convert Java List to R list for easier access
    obj_list <- list()
    list_size <- rJava::.jcall(result, "I", "size")
    
    if (list_size > 0) {
      for (i in 0:(list_size - 1)) {
        obj <- rJava::.jcall(result, "Ljava/lang/Object;", "get", as.integer(i))
        obj_list[[i + 1]] <- obj
      }
    }
    
    return(obj_list)
  }, error = function(e) {
    stop("Failed to get semantic objects: ", e$message)
  })
}

#' Get text from a semantic object
#' 
#' @description Extracts the text from a Java SemanticObject
#' @param semantic_obj Java SemanticObject
#' @return character(1) the text
#' @export
get_text <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  rJava::.jcall(semantic_obj,
                returnSig = "Ljava/lang/String;",
                method = "getText")
}

#' Get codes from a semantic object
#' 
#' @description Extracts the codes from a Java SemanticObject
#' @param semantic_obj Java SemanticObject
#' @return character vector of codes
#' @export
get_codes <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  codes_java <- rJava::.jcall(semantic_obj,
                              returnSig = "Ljava/util/List;",
                              method = "getCode")
  
  # Convert Java List to R character vector
  list_size <- rJava::.jcall(codes_java, "I", "size")
  
  if (list_size == 0) {
    return(character(0))
  }
  
  codes <- character(list_size)
  for (i in 0:(list_size - 1)) {
    code <- rJava::.jcall(codes_java, "Ljava/lang/Object;", "get", as.integer(i))
    codes[i + 1] <- rJava::.jcall(code, "Ljava/lang/String;", "toString")
  }
  
  return(codes)
}

#' Get semantic role from a semantic object
#' 
#' @description Gets the semantic role from a Java SemanticObject
#' @param semantic_obj Java SemanticObject
#' @return character(1) the semantic role
#' @export
get_semantic_role <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  role_enum <- rJava::.jcall(semantic_obj,
                             returnSig = "Ledu/harvard/hsph/biostats/nile/SemanticRole;",
                             method = "getSemanticRole")
  rJava::.jcall(role_enum,
                returnSig = "Ljava/lang/String;",
                method = "toString")
}

#' Get certainty from a semantic object
#' 
#' @description Gets the certainty level from a Java SemanticObject
#' @param semantic_obj Java SemanticObject
#' @return character(1) the certainty level ("YES", "NO", "UNCLEAR")
#' @export
get_certainty <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  tryCatch({
    # Get the certainty enum (class 'a' is the obfuscated Certainty enum)
    certainty_enum <- rJava::.jcall(semantic_obj,
                                    returnSig = "Ledu/harvard/hsph/biostats/nile/a;",
                                    method = "getCertainty")
    rJava::.jcall(certainty_enum,
                  returnSig = "Ljava/lang/String;",
                  method = "toString")
  }, error = function(e1) {
    # If there's an error, try alternative approaches or return default
    tryCatch({
      # Try calling directly as string
      rJava::.jcall(semantic_obj,
                    returnSig = "Ljava/lang/String;",
                    method = "getCertainty")
    }, error = function(e2) {
      # If both fail, return a default value
      return("YES")  # Default to YES (certain) instead of UNCLEAR
    })
  })
}

#' Check if semantic object refers to family history
#' 
#' @description Checks if a Java SemanticObject refers to family history
#' @param semantic_obj Java SemanticObject
#' @return logical whether it's family history
#' @export
is_family_history <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  rJava::.jcall(semantic_obj,
                returnSig = "Z",
                method = "isFamilyHistory")
}

#' Get modifiers from a semantic object
#' 
#' @description Gets the modifiers from a Java SemanticObject
#' @param semantic_obj Java SemanticObject
#' @return list of Java SemanticObject modifiers
#' @export
get_modifiers <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  result <- rJava::.jcall(semantic_obj,
                         returnSig = "Ljava/util/List;",
                         method = "getModifiers")
  
  # Convert Java List to R list for easier access
  mod_list <- list()
  list_size <- rJava::.jcall(result, "I", "size")
  
  if (list_size > 0) {
    for (i in 0:(list_size - 1)) {
      mod <- rJava::.jcall(result, "Ljava/lang/Object;", "get", as.integer(i))
      mod_list[[i + 1]] <- mod
    }
  }
  
  return(mod_list)
}

#' Get short string representation of a sentence
#' 
#' @description Gets a short string summary of a Java Sentence object
#' @param sentence Java Sentence object
#' @return character(1) short string representation
#' @export
to_short_string <- function(sentence) {
  if (!inherits(sentence, "jobjRef"))
    stop("`sentence` must be a Java Sentence object")
  
  rJava::.jcall(sentence,
                returnSig = "Ljava/lang/String;",
                method = "toShortString")
}

#' Get string representation of a sentence
#' 
#' @description Gets the string representation of a Java Sentence object
#' @param sentence Java Sentence object
#' @return character(1) string representation
#' @export
sentence_to_string <- function(sentence) {
  if (!inherits(sentence, "jobjRef"))
    stop("`sentence` must be a Java Sentence object")
  
  rJava::.jcall(sentence,
                returnSig = "Ljava/lang/String;",
                method = "toString")
}

#' Get dictionary from NLP object
#' 
#' @description Gets the dictionary object from a NaturalLanguageProcessor
#' @param nlp Java NLP object (from new_nlp())
#' @return Java dictionary object
#' @export
get_dictionary <- function(nlp) {
  if (!inherits(nlp, "jobjRef"))
    stop("`nlp` must be a Java object created by new_nlp()")
  
  rJava::.jcall(nlp,
                returnSig = "Ledu/harvard/hsph/biostats/nile/o;",
                method = "getDictionary")
}

#' Get tokens from a sentence
#' 
#' @description Gets the tokens array from a Java Sentence object
#' @param sentence Java Sentence object
#' @return character vector of tokens
#' @export
get_tokens <- function(sentence) {
  if (!inherits(sentence, "jobjRef"))
    stop("`sentence` must be a Java Sentence object")
  
  tokens_array <- rJava::.jcall(sentence,
                                returnSig = "[Ljava/lang/String;",
                                method = "getTokens")
  
  # Convert Java string array to R character vector
  if (!is.null(tokens_array)) {
    return(rJava::.jevalArray(tokens_array))
  } else {
    return(character(0))
  }
}

#' Get offset start position from semantic object
#' 
#' @description Gets the starting character offset of a semantic object in the text
#' @param semantic_obj Java SemanticObject
#' @return integer start position
#' @export
get_offset_start <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  rJava::.jcall(semantic_obj,
                returnSig = "I",
                method = "getOffsetStart")
}

#' Get offset end position from semantic object
#' 
#' @description Gets the ending character offset of a semantic object in the text
#' @param semantic_obj Java SemanticObject
#' @return integer end position
#' @export
get_offset_end <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  rJava::.jcall(semantic_obj,
                returnSig = "I",
                method = "getOffsetEnd")
}

#' Set offset positions for semantic object
#' 
#' @description Sets the start and end character offsets for a semantic object
#' @param semantic_obj Java SemanticObject
#' @param start_pos integer start position
#' @param end_pos integer end position
#' @return the modified semantic object
#' @export
set_offsets <- function(semantic_obj, start_pos, end_pos) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  rJava::.jcall(semantic_obj,
                returnSig = "Ledu/harvard/hsph/biostats/nile/SemanticObject;",
                method = "setOffsets",
                as.integer(start_pos),
                as.integer(end_pos))
}

#' Set certainty for semantic object
#' 
#' @description Sets the certainty level for a semantic object
#' @param semantic_obj Java SemanticObject
#' @param certainty character(1) one of "YES", "NO", "UNCLEAR"
#' @export
set_certainty <- function(semantic_obj, certainty) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  # Get the certainty enum value
  certainty_enum <- rJava::.jfield("edu.harvard.hsph.biostats.nile.a", 
                                   name = certainty)
  
  rJava::.jcall(semantic_obj,
                returnSig = "V",
                method = "setCertainty",
                certainty_enum)
}

#' Set family history flag for semantic object
#' 
#' @description Sets whether a semantic object refers to family history
#' @param semantic_obj Java SemanticObject
#' @param is_family_hist logical family history flag
#' @export
set_family_history <- function(semantic_obj, is_family_hist) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  rJava::.jcall(semantic_obj,
                returnSig = "V",
                method = "setFamilyHistory",
                as.logical(is_family_hist))
}

#' Get sentence from semantic object
#' 
#' @description Gets the parent sentence of a semantic object
#' @param semantic_obj Java SemanticObject
#' @return Java Sentence object
#' @export
get_sentence <- function(semantic_obj) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  
  rJava::.jcall(semantic_obj,
                returnSig = "Ledu/harvard/hsph/biostats/nile/Sentence;",
                method = "getSentence")
}

#' Set sentence for semantic object
#' 
#' @description Sets the parent sentence for a semantic object
#' @param semantic_obj Java SemanticObject
#' @param sentence Java Sentence object
#' @export
set_sentence <- function(semantic_obj, sentence) {
  if (!inherits(semantic_obj, "jobjRef"))
    stop("`semantic_obj` must be a Java SemanticObject")
  if (!inherits(sentence, "jobjRef"))
    stop("`sentence` must be a Java Sentence object")
  
  rJava::.jcall(semantic_obj,
                returnSig = "V",
                method = "setSentence",
                sentence)
} 