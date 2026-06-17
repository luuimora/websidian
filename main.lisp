(in-package :websidian)
(defun main ()
  "Точка входа для запуска утилиты из командной строки."
  (let ((args (uiop:command-line-arguments)))
    
    ;; Проверяем наличие двух обязательных аргументов
    (if (< (length args) 2)
        (progn
          (format t "Ошибка: Недостаточно аргументов.~%")
          (format t "Использование: file-converter <входной_файл.md> <выходной_файл.html> [файл_стилей.css]~%"))
        
        ;; Распаковываем аргументы
        (let ((input-file (first args))
              (output-file (second args))
              ;; Третий аргумент может быть nil
              (css-file (third args)))
          
          (format t "Начинаю компиляцию...~%")
          (format t "  Входной файл: ~A~%" input-file)
          (format t "  Выходной файл: ~A~%" output-file)
          
          (when css-file
            (format t "  Файл стилей: ~A~%" css-file))
          
          ;; Запускаем конвейер
          (convert-file-to-html input-file output-file css-file)
          
        (format t "Успешно завершено!~%")
        (uiop:quit 0)))))