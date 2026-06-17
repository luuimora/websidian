(in-package :websidian)
(defun highlight-p (line i len) "Checks whether a character sequence is a valid Markdown highlight."
  (or (and (< (1+ i) len)
           (char= (char line i) #\=)
           (char= (char line (1+ i)) #\=))
      (and (< (1+ i) len)
           (char= (char line i) #\=)
           (char= (char line (1+ i)) #\=))))

(defun strikethrough-p (line i len) "Checks whether a character sequence is a valid Markdown strikethrough."
  (or (and (< (1+ i) len)
           (char= (char line i) #\~)
           (char= (char line (1+ i)) #\~))
      (and (< (1+ i) len)
           (char= (char line i) #\~)
           (char= (char line (1+ i)) #\~))))

(defun italic-p (line i len) "Checks whether a character sequence is a valid Markdown italic."
  (or (and (< (1+ i) len)
           (char= (char line i) #\*))
      (and (< (1+ i) len)
           (char= (char line i) #\_))))

(defun bold-p (line i len) "Checks whether a character sequence is a valid Markdown bold."
  (or (and (< (1+ i) len)
           (char= (char line i) #\*)
           (char= (char line (1+ i)) #\*))
      (and (< (1+ i) len)
           (char= (char line i) #\_)
           (char= (char line (1+ i)) #\_))))

(defun no-format-p (line i len) "Checks whether a character sequence is a valid Markdown backslash escaping."
  (and (< (1+ i) len)
       (char= (char line i) #\\)))

(defun link-p (line i len) "Checks whether a character sequence is a valid Wikilink."
  (or (and (< (1+ i) len)
           (char= (char line i) #\[)
           (char= (char line (1+ i)) #\[))
      (and (< (1+ i) len)
           (char= (char line i) #\])
           (char= (char line (1+ i)) #\]))))

(defun list-item-p (line) "Checks, whether a string is valid markdown list item"
  (and (stringp line)
       (let ((trimmed (string-left-trim '(#\Space #\Tab) line)))
         (and (>= (length trimmed) 2)
              (find (char trimmed 0) "-*+" :test #'char=)
              (char= (char trimmed 1) #\Space)))))

(defun has-pipe-p (line)
  "Checks for a pipe symbol"
  (and (stringp line)
       (position #\| line)))

(defun delimiter-row-p (line)
  "Checks whether a string has only markdown table breaks"
  (and (has-pipe-p line)
       (loop for char across line
               always (find char "|-: " :test #'char=))))

(defun table-p (current-line next-line)
  "Predicate that is smarter than me. Returns T only if next line is table break line."
  (and (has-pipe-p current-line)
       (stringp next-line)
       (delimiter-row-p next-line)))

(defun link-p-local (str)
  "Another smartie. Checkes whether a string is a local link like [[#Header]].
   Returns T and text of header (for free, only today!)."
  (let ((len (length str)))
    (when (and (>= len 5) 
               (string= str "[[" :end1 2) 
               (string= str "]]" :start1 (- len 2)) 
               (char= (char str 2) #\#))
          (values t (subseq str 3 (- len 2))))))

(defun link-p-absolute (str)
  "Checks whether a string is absolute markdowm link like [[Note]] или [[Note#Ankor]].
   Returns T, name of a note (as second value) and header to be ankored (third value, may be NIL if not extracted from given string)."
  (let ((len (length str)))
    (when (and (>= len 5) 
               (string= "[[" str :end2 2) 
               (string= "]]" str :start2 (- len 2)) 
               (not (char= (char str 2) #\#))) 
          (let ((hash-pos (position #\# str :start 2 :end (- len 2))))
            (if hash-pos
                (let ((note (subseq str 2 hash-pos))
                      (header (subseq str (1+ hash-pos) (- len 2))))
                  (values t
                    note
                    (if (string= header "") nil header)))
                (values t
                  (subseq str 2 (- len 2))
                  nil))))))

(defun starts-with-p (string prefix) "Checks if given string starts with given prefix"
  (let ((mismatch (mismatch string prefix)))
    (or (not mismatch) (>= mismatch (length prefix)))))


(defun blank-line-p (line) "Check whether your soul is blank. Haha. A given string."
  (string= (string-trim '(#\Space #\Tab #\Return #\Newline) line) ""))

(defun heading-level-p (line) "Checks for header"
  (let ((count (position-if-not (lambda (c) (char= c #\#)) line)))
    (if (and count
             (> count 0)
             (<= count 6)
             (< count (length line))
             (char= (char line count) #\Space))
        count
        nil)))

(defun raw-html-p (line)
  "Checks for html tag in line"
  (let ((trimmed (string-left-trim " " line)))
    (and (> (length trimmed) 1)
         (char= (char trimmed 0) #\<)
         (or (alpha-char-p (char trimmed 1))
             (char= (char trimmed 1) #\/)))))

(defun hr-p (line)
  "Checks for breaker line (***, ---, ___)."
  (when (stringp line) ; Защита от NIL
        (let ((trimmed (string-left-trim '(#\Space #\Tab) line)))
          (when (>= (length trimmed) 3)
                (let ((first-char (char trimmed 0)))
                  ;; Разделитель должен начинаться с *, - или _
                  (and (find first-char "*-_")
                       ;; Все остальные символы должны быть либо такими же, либо пробельными
                       (loop for char across trimmed
                               always (or (char= char first-char)
                                          (char= char #\Space)
                                          (char= char #\Tab)))))))))

(defun image-link-p (line i len)
  "Checks if given line is image-link on given index i (![[...]]).
   Returns (VALUES T Name-of-image-file alt-text (for the fuck's sake!) end-position).
   If not passed returns (VALUES NIL NIL NIL NIL)."
  (when (and (< (+ i 4) len) ; Минимальная длина для "![[x]]"
             (char= (char line i) #\!)
             (char= (char line (1+ i)) #\[)
             (char= (char line (+ i 2)) #\[))
        (let ((close-pos (search "]]" line :start2 (+ i i))))
          (when close-pos
                (let* ((content-start (+ i 3))
                       (content (subseq line content-start close-pos))
                       (pipe-pos (position #\| content))
                       (filename (if pipe-pos
                                     (string-trim '(#\Space #\Tab) (subseq content 0 pipe-pos))
                                     (string-trim '(#\Space #\Tab) content)))
                       (alt-text (if pipe-pos
                                     (string-trim '(#\Space #\Tab) (subseq content (1+ pipe-pos)))
                                     "")))
                  (values t filename alt-text (+ close-pos 2)))))))