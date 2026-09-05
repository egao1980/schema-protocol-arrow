(defsystem "schema-protocol-arrow"
  :version "0.1.1"
  :description "Arrow schema emit + table↔objects for schema-protocol"
  :author "egao1980"
  :license "MIT"
  :depends-on ("schema-protocol" "arrow-protocol" "closer-mop")
  :properties (:cl-repo (:ci ()))
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "emit")
               (:file "table")
               (:file "protocol"))
  :in-order-to ((test-op (test-op "schema-protocol-arrow/tests"))))

(defsystem "schema-protocol-arrow/tests"
  :depends-on ("schema-protocol-arrow" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "emit-test")
               (:file "table-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
