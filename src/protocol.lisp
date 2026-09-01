(in-package #:schema-protocol-arrow)

(defmethod arrow-schema ((schema symbol) &key)
  (emit schema))

(defmethod arrow-schema ((schema standard-object) &key)
  (emit schema))
