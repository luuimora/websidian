(in-package :cl-user)

(defpackage :websidian
  (:use :cl)
  (:import-from :uiop
                :command-line-arguments
                :quit)
  (:export :main))