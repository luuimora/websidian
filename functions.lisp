(in-package :websidian)
(defun compile-markdown-document (lines)
  "Makes an AST out of poor markdown file."

  (let* ((ast (block-walker lines))

         (html-blocks (mapcar #'render-ast-to-html ast)))

    (format nil "~{~A~^~%~}" html-blocks)))

(defun convert-file-to-html (input-filename output-filename css-filename)
  "Reads html, css, calls a compiler"

  (let ((raw-lines (with-open-file (stream input-filename :external-format :utf-8)
                     (loop for line = (read-line stream nil)
                           while line
                           collect line)))
        (css-content (if css-filename
                         (read-file-as-string css-filename)
                         "")))

    (let ((final-html (compile-markdown-document raw-lines)))

      (with-open-file (out output-filename
                           :direction :output
                           :if-exists :supersede
                           :external-format :utf-8)

        (format out "<!DOCTYPE html>~%<html lang=\"ru\">~%<head>~%")
        (format out "  <meta charset=\"utf-8\">~%")

        (when (not (string= css-content ""))
              (format out "  <style>~%~A  </style>~%" css-content))

        (format out "</head>~%<body>~%")
        (write-string final-html out)
        (format out "~%</body>~%</html>")))))


(defun generate-slug (str)
  (string-trim "-"
               (with-output-to-string (out)
                 (let ((last-was-hyphen nil)
                       (lower (string-downcase str)))
                   (loop for char across lower do
                           (cond
                            ((alphanumericp char)
                              (write-char char out)
                              (setf last-was-hyphen nil))
                            ((or (char= char #\Space) (char= char #\-))
                              (unless last-was-hyphen
                                (write-char #\- out)
                                (setf last-was-hyphen t)))
                            (t nil)))))))

(defun split-table-row (line)
  "Breakes a line by pipe symbol and returns trimmed values"
  (let* ((trimmed (string-trim " |" line))
         (len (length trimmed))
         (result nil)
         (start 0))
    (loop for i from 0 to len
          do (when (or (= i len) (char= (char trimmed i) #\|))
                   (push (string-trim " " (subseq trimmed start i)) result)
                   (setf start (1+ i))))
    (nreverse result)))

(defun parse-table-alignments (delimiter-line)
  "Returns :left, :center, :right out of table breaker line"
  (let ((cells (split-table-row delimiter-line)))
    (loop for cell in cells
          for len = (length cell)
          collect (cond
                   ((and (> len 1)
                         (char= (char cell 0) #\:)
                         (char= (char cell (1- len)) #\:))
                     :center)
                   ((and (> len 0)
                         (char= (char cell (1- len)) #\:))
                     :right)
                   (t :left)))))

(defun process-table (lines)
  "Returns a table and number of consumed strings. Bon appetit."
  (let* ((headers (split-table-row (first lines)))
         (alignments (parse-table-alignments (second lines)))
         (rows nil)
         (consumed 2))
    (loop for line in (cddr lines)
          while (and (stringp line) (has-pipe-p line))
          do (push (split-table-row line) rows)
            (incf consumed))
    (values (make-ast-node :type :table
                           :headers headers
                           :alignments alignments
                           :rows (nreverse rows))
      consumed)))

(defun parse-list-item-text (line)
  "Deletes list item marker and a space, returns only content of one point in pointed list"
  (let ((trimmed (string-left-trim '(#\Space #\Tab) line)))
    (subseq trimmed 2)))

(defun read-file-as-string (filename)
  "Reads a file, returns it as one string"
  (with-output-to-string (out)
    (with-open-file (in filename :direction :input
                        :external-format :utf-8
                        :if-does-not-exist nil)
      (when in
            (loop for line = (read-line in nil)
                  while line
                  do (write-line line out))))))