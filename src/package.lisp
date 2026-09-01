(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; OCI pin may lack ARROW-SCHEMA — intern so :import-from works.
  (let* ((pkg (find-package '#:schema-protocol))
         (sym (intern "ARROW-SCHEMA" pkg)))
    (export sym pkg)))

(defpackage #:schema-protocol-arrow
  (:use #:cl)
  (:nicknames #:stack-schema-arrow)
  (:import-from #:closer-mop
                #:slot-definition-name
                #:slot-definition-type)
  (:import-from #:schema-protocol
                #:schema-of
                #:schema-slots
                #:schema-class
                #:schema-object
                #:find-schema
                #:schema-slot
                #:schema-tag
                #:schema-variants
                #:enum-of
                #:enum-members
                #:finalize-schema
                #:type-kind
                #:type-args
                #:sequence-element-type
                #:slot-is-required-p
                #:slot-optional-p
                #:slot-wire-p
                #:slot-dump-p
                #:slot-wire-key
                #:slot-minimum
                #:slot-maximum
                #:arrow-schema
                #:parse
                #:dump
                #:schema-error)
  (:import-from #:arrow-protocol
                #:make-arrow-field
                #:make-arrow-schema
                #:arrow-schema-p
                #:arrow-schema-fields
                #:arrow-field-name
                #:arrow-field-type
                #:arrow-field-nullable
                #:table-from-rows
                #:table-to-rows
                #:arrow-table-p)
  (:export #:arrow-schema-error
           #:arrow-schema-error-message
           #:emit
           #:table-from-objects
           #:objects-from-table
           #:arrow-schema))

(in-package #:schema-protocol-arrow)

(unless (and (fboundp 'arrow-schema)
             (typep (symbol-function 'arrow-schema) 'generic-function))
  (defgeneric arrow-schema (schema &key)
    (:documentation "Emit an arrow-protocol:arrow-schema.")))
