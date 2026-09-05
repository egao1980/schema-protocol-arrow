(in-package #:schema-protocol-arrow)

(defclass arrow-schema-backend (schema-format-backend) ()
  (:documentation "schema-protocol format backend for :arrow."))

(defmethod backend-emit-schema ((backend arrow-schema-backend) schema &key &allow-other-keys)
  (declare (ignore backend))
  (emit schema))

(defmethod backend-parse-schema ((backend arrow-schema-backend) source
                                 &key name package &allow-other-keys)
  (declare (ignore backend))
  (apply #'compile-schema source
         (append (when name (list :name name))
                 (when package (list :package package)))))

(eval-when (:load-toplevel :execute)
  (register-schema-format :arrow (make-instance 'arrow-schema-backend)))

(defmethod arrow-schema ((schema symbol) &key)
  (emit schema))

(defmethod arrow-schema ((schema standard-object) &key)
  (emit schema))
