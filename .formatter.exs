[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 100,
  import_deps: [:ecto],
  subdirectories: ["priv/*/migrations"]
]
