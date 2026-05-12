# Checked Outputs By System

Leanix now has a checked boundary below `ValidatedFlake`:

```lean
CheckedSystemOutputs system
```

It carries the package graph, apps, dev shells, checks, formatter, input names,
and named evidence that the output-family references resolve inside the same
system package graph.

The renderer still behaves the same. This slice makes validation produce a
reusable checked value that artifacts and future renderer refactors can point
at directly.
