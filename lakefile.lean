import Lake
open Lake DSL

package «leanix» where

lean_lib Leanix where

@[default_target]
lean_exe leanix where
  root := `Main
