(in-package #:schema-protocol-arrow)

(define-condition arrow-schema-error (schema-error)
  ((message :initarg :message :reader arrow-schema-error-message :initform nil))
  (:report (lambda (c s)
             (format s "Arrow schema error~@[: ~A~]" (arrow-schema-error-message c)))))
