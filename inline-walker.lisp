(in-package :websidian)
(defun inline-walker (line) "Uses the LOOP macro to scan a line and identify Markdown inline syntax."
  (let ((result (make-string-output-stream))
        (len (length line))
        (i 0)
        (in-bold nil)
        (in-italic nil)
        (in-highlight nil)
        (in-strikethrough nil))

    (loop while (< i len)
          do (cond
              ((no-format-p line i len)
                (write-char (char line (1+ i)) result)
                (incf i 2))

              ((bold-p line i len)
                (setf in-bold (not in-bold))
                (write-string (if in-bold "<b>" "</b>") result)
                (incf i 2))

              ((strikethrough-p line i len)
                (setf in-strikethrough (not in-strikethrough))
                (write-string (if in-strikethrough "<s>" "</s>") result)
                (incf i 2))

              ((italic-p line i len)
                (setf in-italic (not in-italic))
                (write-string (if in-italic "<i>" "</i>") result)
                (incf i 1))

              ((highlight-p line i len)
                (setf in-highlight (not in-highlight))
                (write-string (if in-highlight "<mark>" "</mark>") result)
                (incf i 2))

              ;; I'm sorry all this bullshit lower is for links maybe I rewrite it letter right now I don't give a shit
              ((and (< (1+ i) len)
                    (char= (char line i) #\[)
                    (char= (char line (1+ i)) #\[))
                (let ((close-pos (search "]]" line :start2 i)))
                  (if close-pos

                      (let ((raw-link (subseq line i (+ close-pos 2))))
                        (cond

                         ((link-p-local raw-link)
                           (multiple-value-bind (is-local header) (link-p-local raw-link)
                             (declare (ignore is-local))

                             (write-string (format nil "<a href=\"#~A\">~A</a>"
                                             (generate-slug header) header)
                                           result)))

                         ((link-p-absolute raw-link)
                           (multiple-value-bind (is-abs note header) (link-p-absolute raw-link)
                             (declare (ignore is-abs))
                             (let* ((pipe-pos (position #\| note))

                                    (actual-note (if pipe-pos (subseq note 0 pipe-pos) note))

                                    (display-text (if pipe-pos (subseq note (1+ pipe-pos)) nil)))

                               (if header

                                   (let ((final-display (or display-text header)))
                                     (write-string (format nil "<a href=\"~A.html#~A\">~A</a>"
                                                     actual-note (generate-slug header) final-display)
                                                   result))

                                   (let ((final-display (or display-text actual-note)))
                                     (write-string (format nil "<a href=\"~A.html\">~A</a>"
                                                     actual-note final-display)
                                                   result)))))))

                         (setf i (+ close-pos 2)))

                        (progn
                         (write-char #\[ result)
                         (incf i 1)))))


                ((image-link-p line i len)
                 (multiple-value-bind (is-img filename alt-text next-pos)
                     (image-link-p line i len)
                   (declare (ignore is-img))

                   (format result "<img src=\"~A\" alt=\"~A\" title=\"~A\" />"
                     filename
                     (if (string= alt-text "") filename alt-text)
                     alt-text)

                   (setf i next-pos)))
                   
                (t
                 (write-char (char line i) result)
                 (incf i 1))))

            (get-output-stream-string result)))