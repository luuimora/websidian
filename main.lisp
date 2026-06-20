;;
;; Hostsidian. Converts .md to .html
;; Copyright (C) 2026  Artyom Gorlov
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;

(in-package :hostsidian)
(defun main ()
  (let ((args (uiop:command-line-arguments)))
    (cond
      ((equal "-v" (first args))
       (format t "Hostsidian v.0.2.0 distributed under GPL 3 licence.~%")
       (uiop:quit 0))

      ((< (length args) 2)
       (format *error-output* "Error: Not enough arguments.~%")
       (format *error-output* "Use: ./hostsidian <input.md> <output.html> [style.css]~%")
       (uiop:quit 1))

      (t
       (let ((input-file (first args))
             (output-file (second args))
             (css-file (third args)))

         (format t "Compiling...~%")
         (format t "  Input: ~A~%" input-file)
         (format t "  Output: ~A~%" output-file)

         (when css-file
           (format t "  Style file: ~A~%" css-file))

         (convert-file-to-html input-file output-file css-file)

         (format t "Success!~%")
         (uiop:quit 0))))))