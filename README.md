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

`parse-schema` for `:arrow` rebuilds a **lossy** `schema-class` from an `arrow-schema`, field JSON, IPC schema bytes, or a Parquet file (footer field 5 `ARROW:schema`, else the SchemaElement tree): primitives / lists / structs / nullability only. No constraints, no enums, no tagged-union identity (flattened columns → one class, `:extra :allow`).

```lisp
(parse-schema (stack-arrow:parquet-schema bytes) :format :arrow)
(parse-schema bytes :format :arrow)   ; PAR1 / IPC accepted directly
```

CI: canned [`cl-repository`](https://github.com/egao1980/cl-repository).

## License

MIT
