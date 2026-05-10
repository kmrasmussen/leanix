# Golden Renderer Tests

Ticket 0004 adds committed renderer fixtures under `e2e/golden/`.

The Rust e2e harness now checks selected generated flakes in this order:

1. render the Lean value to `generated/flake.nix`
2. compare the generated text to the committed golden fixture
3. run `nix flake check path:./generated`

That ordering is intentional. Shape churn should fail before Nix tells us the
flake still happens to evaluate.

The first pinned cases are the hello flake, the typed closure flake, and the
CLI schema flake. The showcase keeps its local expected output next to the
standalone example because it is also documentation for that example.
