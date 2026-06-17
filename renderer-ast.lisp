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
(defun render-ast-to-html (node)
  (cond
   ((eq (ast-node-type node) :blockquote)
     (format nil "<blockquote>~%~{~A~%~}</blockquote>"
       (mapcar #'render-ast-to-html (ast-node-children node))))

   ((eq (ast-node-type node) :raw-html)
     (format nil "~A" (ast-node-content node)))

   ((eq (ast-node-type node) :heading)
     (let ((parsed-inline-text (inline-walker (ast-node-content node))))
       (format nil "<h~D id=~D>~A</h~D>"
         (ast-node-level node)
         (generate-slug parsed-inline-text)
         parsed-inline-text
         (ast-node-level node))))

   ((eq (ast-node-type node) :code)
    (format nil "  <pre><code>~A</pre></code>" (ast-node-content node)))

   ((eq (ast-node-type node) :ul)
     (format nil "<ul>~%~{~A~^~%~}~%</ul>"
       (mapcar #'render-ast-to-html (ast-node-children node))))
   ((eq (ast-node-type node) :hr)
     (format nil "<hr />~%"))
     
   ((eq (ast-node-type node) :li)
     (let ((parsed-inline-text (inline-walker (ast-node-content node))))
       (format nil "  <li>~A</li>" parsed-inline-text)))

   ((eq (ast-node-type node) :paragraph)
     (let ((parsed-inline-text (inline-walker (ast-node-content node))))
       (format nil "<p>~A</p>" parsed-inline-text)))

   ((eq (ast-node-type node) :table)
     (with-output-to-string (s)
       (format s "<table>~%")
       (format s "  <thead>~%    <tr>~%")
       (loop for header in (ast-node-headers node)
             for align in (ast-node-alignments node)
             do (format s "      <th style=\"text-align: ~A;\">~A</th>~%"
                  (string-downcase (symbol-name align))
                  (inline-walker header)))
       (format s "    </tr>~%  </thead>~%")

       (format s "  <tbody>~%")
       (loop for row in (ast-node-rows node)
             do (format s "    <tr>~%")
               (loop for cell in row
                     for align in (ast-node-alignments node)
                     do (format s "      <td style=\"text-align: ~A;\">~A</td>~%"
                          (string-downcase (symbol-name align))
                          (inline-walker cell)))
               (format s "    </tr>~%"))
       (format s "  </tbody>~%</table>")))))