(lang dune 3.15)

(name ochat)

(generate_opam_files true)

(source
 (github ilswyn/ochat))

(authors "Eric Newton")

(maintainers "Eric Newton")

(license LICENSE)

(documentation https://https://github.com/rileynewton/ochat/README.md)

(package
 (name ochat)
 (synopsis "A simple one on one chat application")
 (description "Project to learn OCaml and multicore OCaml libraries")
 (depends ocaml dune eio eio_main domainslib cmdliner ounit2)
 (tags
  ("ochat" "ocaml" "eio" "multicore")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
