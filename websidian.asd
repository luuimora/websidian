(asdf:defsystem #:websidian
  :description "Converts a given file into HTML. Can embedd an CSS into file."
  :author "Artyom Gorlov"
  :license "GPL 3.0"
  :version "1.0.0"
  :serial t
  :components ((:file "package")
               (:file "predicates")
               (:file "inline-walker")
               (:file "block-walker")
               (:file "functions")
               (:file "main")
               (:file "renderer-ast"))
               
  :defsystem-depends-on (:deploy)

  :build-operation "deploy-console-op"

  :build-pathname "websidian"

  :entry-point "websidian:main")