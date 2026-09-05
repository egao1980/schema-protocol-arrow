(in-package #:schema-protocol-arrow)

(defvar *generated-package* (find-package '#:schema-protocol-arrow.generated))

(defstruct compile-ctx
  (package *generated-package*))

(defun %sanitize (string)
  (let ((s (substitute #\- #\_ (substitute #\- #\Space (string string)))))
    (if (plusp (length s))
        (string-upcase s)
        "SCHEMA")))

(defun %name-symbol (name ctx)
  (etypecase name
    (symbol
     (if (eq (symbol-package name) (compile-ctx-package ctx))
         name
         (intern (symbol-name name) (compile-ctx-package ctx))))
    (string (intern (%sanitize name) (compile-ctx-package ctx)))))

(defun %arrow-type-args (spec)
  (if (consp spec) (rest spec) nil))

(defun %ht-get (table key)
  (and (hash-table-p table) (gethash key table)))

(defun %field-from-json (node)
  (unless (hash-table-p node)
    (error 'arrow-schema-error :message "arrow field must be an object"))
  (make-arrow-field :name (%ht-get node "name")
                    :type (%type-from-json (%ht-get node "type"))
                    :nullable (multiple-value-bind (v present)
                                  (and (hash-table-p node) (gethash "nullable" node))
                                (if present (and v t) t))))

(defun %type-from-json (spec)
  (cond
    ((null spec) :utf8)
    ((symbolp spec) spec)
    ((stringp spec)
     (let ((s (string-downcase spec)))
       (cond
         ((member s '("utf8" "string" "str") :test #'string=) :utf8)
         ((member s '("bool" "boolean") :test #'string=) :bool)
         ((string= s "null") :null)
         ((member s '("int8" "int16" "int32" "int64"
                      "uint8" "uint16" "uint32" "uint64"
                      "float32" "float64" "binary")
                  :test #'string=)
          (intern (string-upcase s) :keyword))
         (t :utf8))))
    ((hash-table-p spec)
     (let ((kind (string-downcase (princ-to-string (%ht-get spec "kind")))))
       (cond
         ((string= kind "list")
          (list :list (%type-from-json (%ht-get spec "item"))))
         ((string= kind "struct")
          (cons :struct
                (map 'list #'%field-from-json
                     (coerce (%ht-get spec "fields") 'list))))
         (t :utf8))))
    (t spec)))

(defun %octet-vector-p (x)
  (and (arrayp x)
       (not (stringp x))
       (plusp (length x))
       (equal (array-element-type x) '(unsigned-byte 8))))

(defun %starts-with-octets (bytes prefix)
  (and (>= (length bytes) (length prefix))
       (loop for i from 0 below (length prefix)
             always (= (aref bytes i) (aref prefix i)))))

(defun %parquet-schema-fn ()
  (let ((s (find-symbol "PARQUET-SCHEMA" "ARROW-PROTOCOL")))
    (and s (fboundp s) s)))

(defun %as-arrow-schema (source)
  (cond
    ((null source)
     (error 'arrow-schema-error :message "arrow schema source is empty"))
    ((arrow-schema-p source) source)
    ((%octet-vector-p source)
     (cond
       ((or (%starts-with-octets source #(#x50 #x41 #x52 #x31))   ; PAR1
            (%starts-with-octets source #(#x50 #x41 #x52 #x45)))  ; PARE
        (let ((fn (%parquet-schema-fn)))
          (unless fn
            (error 'arrow-schema-error
                   :message "arrow-protocol is too old to parse Parquet ARROW:schema"))
          (funcall fn source)))
       ((or (%starts-with-octets source #(#xFF #xFF #xFF #xFF))
            (%starts-with-octets source #(#x41 #x52 #x52 #x4F #x57 #x31))) ; ARROW1
        (arrow-table-schema (decode-ipc source)))
       (t
        (make-arrow-schema (map 'list #'%coerce-field source)))))
    ((and (vectorp source) (not (stringp source)))
     (make-arrow-schema (map 'list #'%coerce-field source)))
    ((and (consp source) (not (hash-table-p source)))
     (make-arrow-schema (mapcar #'%coerce-field source)))
    ((hash-table-p source)
     (let ((fields (%ht-get source "fields")))
       (unless fields
         (error 'arrow-schema-error :message "arrow schema object has no fields"))
       (make-arrow-schema (map 'list #'%coerce-field (coerce fields 'list)))))
    (t
     (error 'arrow-schema-error
            :message (format nil "cannot parse Arrow schema from ~S" (type-of source))))))

(defun %coerce-field (field)
  (cond
    ((arrow-protocol:arrow-field-p field) field)
    ((hash-table-p field) (%field-from-json field))
    (t (error 'arrow-schema-error :message "arrow field must be a field or object"))))

(defun %lisp-type (spec ctx &key name-hint)
  (let ((head (arrow-protocol:type-head spec)))
    (case head
      (:utf8 'string)
      (:bool 'boolean)
      (:null :null)
      ((:int8 :int16 :int32 :int64 :uint8 :uint16 :uint32 :uint64) 'integer)
      ((:float32 :float64) 'number)
      (:binary '(vector (unsigned-byte 8)))
      (:list
       `(vector ,(%lisp-type (or (first (%arrow-type-args spec)) :utf8) ctx
                             :name-hint (and name-hint (format nil "~A-item" name-hint)))))
      (:struct
       (let ((n (or name-hint (gentemp "STRUCT" (compile-ctx-package ctx)))))
         (%fill-struct ctx n (%arrow-type-args spec))
         (%name-symbol n ctx)))
      (t t))))

(defun %fill-struct (ctx name fields)
  (let ((sym (%name-symbol name ctx))
        (slots '()))
    (dolist (field fields)
      (let* ((fname (arrow-field-name field))
             (fsym (%name-symbol fname ctx))
             (optional (arrow-field-nullable field))
             (inner (%lisp-type (arrow-field-type field) ctx :name-hint fname))
             (ftype (if (and optional (not (eq inner :null)))
                        `(or :null ,inner)
                        inner)))
        (push `(:name ,fsym
                :type ,ftype
                :initargs (,(intern (symbol-name fsym) :keyword))
                :readers (,fsym)
                :writers ((setf ,fsym))
                :key ,fname
                :required ,(not optional)
                :optional ,optional)
              slots)))
    (ensure-class sym
                  :metaclass (find-class 'schema-class)
                  :direct-superclasses (list (find-class 'schema-object))
                  :direct-slots (nreverse slots)
                  :extra :allow)
    (find-class sym)))

(defun compile-schema (source &key name (package *generated-package*) &allow-other-keys)
  "arrow-schema / field JSON / IPC octets / Parquet octets → schema-class.

   Lossy: no constraints, no enums, no tagged-union identity. Structs become
   nested classes; nullability becomes :optional. Extra keys are :allow so a
   flattened tagged emit can still parse a sparse row.

   Parquet octets use arrow-protocol `parquet-schema` (field-5 ARROW:schema,
   else the SchemaElement tree). This is the schema-protocol `:arrow` backend;
   call it via `parse-schema` / `emit-schema` `:format :arrow`."
  (let* ((schema (%as-arrow-schema source))
         (ctx (make-compile-ctx :package package))
         (root (or name (gentemp "SCHEMA" package))))
    (%fill-struct ctx root (arrow-schema-fields schema))))
