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
               ((starts-with-p current-line "> ")
                 (push (make-ast-node :type :blockquote
                                      :children (block-walker (list (subseq current-line 2))))
                       ast)
                 (setf lines (rest lines)))

               (t
                 (push (make-ast-node :type :paragraph
                                      :content current-line)
                       ast)
                 (setf lines (rest lines))))))

    (nreverse ast)))