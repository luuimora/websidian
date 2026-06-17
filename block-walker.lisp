;;
;; Websidian. Converts .md to .html
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


(in-package :websidian)
(defstruct ast-node
  type
  content
  children
  level
  headers
  alignments
  rows
  items)

(defun block-walker (lines)
  (let ((ast '())
        (in-code-block nil)
        (code-buffer '()))
    (loop while lines do
            (let ((current-line (first lines))
                  (next-line (second lines)))
              (cond
              ((starts-with-p current-line "```")
                 (if in-code-block
                     (progn
                      (push (make-ast-node :type :code
                                           :content (format nil "~{~A~^~%~}" (nreverse code-buffer)))
                            ast)
                      (setf in-code-block nil)
                      (setf code-buffer '()))
                     (setf in-code-block t))
                 (setf lines (rest lines)))

               (in-code-block
                 (push current-line code-buffer)
                 (setf lines (rest lines)))

               ((blank-line-p current-line)
                 (setf lines (rest lines)))

               ((hr-p current-line)
                 (push (make-ast-node :type :hr :content nil) ast)
                 (setf lines (rest lines)))

               ((raw-html-p current-line)
                 (push (make-ast-node :type :raw-html :content current-line) ast)
                 (setf lines (rest lines)))

               ((table-p current-line next-line)
                 (multiple-value-bind (table-node consumed) (process-table lines)
                   (push table-node ast)
                   (setf lines (nthcdr consumed lines))))

               ((heading-level-p current-line)
                 (let* ((level (heading-level-p current-line))
                        (text (subseq current-line (1+ level))))
                   (push (make-ast-node :type :heading
                                        :level level
                                        :content text)
                         ast))
                 (setf lines (rest lines)))
               ((list-item-p current-line)
                 (let ((li-nodes '())
                       (consumed 0))
                   (loop for iter-line in lines
                         while (list-item-p iter-line)
                         do (push (make-ast-node :type :li
                                                 :content (parse-list-item-text iter-line))
                                  li-nodes)
                           (incf consumed))
                   (push (make-ast-node :type :ul
                                        :children (nreverse li-nodes))
                         ast)
                   (setf lines (nthcdr consumed lines))))

               ((starts-with-p current-line ">")
                 (let* ((has-space (and (> (length current-line) 1)
                                        (char= (char current-line 1) #\Space)))
                        (prefix-len (if has-space 2 1))
                        (content (subseq current-line prefix-len)))
                   (push (make-ast-node :type :blockquote
                                        :children (block-walker (list content)))
                         ast)
                   (setf lines (rest lines))))

               (t
                 (push (make-ast-node :type :paragraph
                                      :content current-line)
                       ast)
                 (setf lines (rest lines))))))

    (nreverse ast)))