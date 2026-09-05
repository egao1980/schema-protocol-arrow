# schema-protocol-arrow

Arrow schema emit + table↔objects for [`schema-protocol`](https://github.com/egao1980/schema-protocol).

Does **not** own bytes — [`arrow-protocol`](https://github.com/egao1980/arrow-protocol) is the IPC/Parquet codec. This package maps `defschema` → `arrow-schema` and objects ↔ tables.

```lisp
(asdf:load-system "schema-protocol-arrow")

(stack-schema-arrow:emit 'user)
(stack-schema:emit-schema 'user :format :arrow)
(stack-schema:arrow-schema 'user)   ; same

(let ((table (stack-schema-arrow:table-from-objects 'user users)))
  (serdes-protocol:encode table :format :parquet)
  (stack-schema-arrow:objects-from-table 'user
    (serdes-protocol:decode octets :format :parquet)))
```

Single-object `dump obj :format :arrow` stays the serdes hash-table path — it does **not** wrap one object as a 1-row table.

`parse-schema` for `:arrow` is not implemented (signals `schema-error`).

CI: canned [`cl-repository`](https://github.com/egao1980/cl-repository).

## License

MIT
