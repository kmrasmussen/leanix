import Leanix.Examples

namespace Leanix
namespace ProofCarryingCliClosure

abbrev helloToolPackage : Package .x86_64_linux :=
  Examples.helloToolPackage

abbrev helloWrapperPackage : Package .x86_64_linux :=
  Examples.helloWrapperPackage

abbrev showcaseCliProject : CliProject .x86_64_linux :=
  Examples.showcaseCliProject

def showcaseValidatedSchema : Except SchemaError (ValidatedSchema (CliProject .x86_64_linux)) :=
  Examples.showcaseValidatedSchema

abbrev checkedPackageGraph : CheckedPackageGraph .x86_64_linux :=
  Examples.closureCheckedPackageGraph

end ProofCarryingCliClosure
end Leanix
