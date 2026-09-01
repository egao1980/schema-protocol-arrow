(in-package #:schema-protocol-arrow)

(defun table-from-objects (schema objects)
  "Sequence of schema objects → arrow-table using EMIT schema."
  (let ((arrow (emit schema)))
    (table-from-rows
     (map 'list (lambda (o) (dump o)) (coerce objects 'list))
     :schema arrow)))

(defun objects-from-table (schema table)
  "arrow-table → vector of parsed schema objects."
  (unless (arrow-table-p table)
    (error 'arrow-schema-error :message "objects-from-table expects an arrow-table"))
  (map 'vector
       (lambda (row) (parse schema row))
       (table-to-rows table)))
