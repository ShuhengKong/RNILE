#' @import rJava
.onLoad <- function(libname, pkgname) {
  # locate the JAR inside your installed package
  jar <- system.file("java", "NILE.jar", package = pkgname)
  if (file.exists(jar)) {
    # start (or attach) the JVM with your JAR on the classpath
    rJava::.jinit(classpath = jar)
  } else {
    warning("Could not find NILE.jar in inst/java/")
  }
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("RNILE package loaded. Java VM initialized with NILE.jar")
} 