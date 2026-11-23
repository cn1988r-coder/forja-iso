# Vendor tools

## GitRepo

The upstream GitRepo project is tracked as a Git submodule at `vendor/gitrepo`.
The pinned upstream revision is recorded by the submodule gitlink in the VENOM
OS repository. Keep upstream source and license intact.

GitRepo is a Python/shell application. It is not the Manjaro ISO build engine
used by VENOM OS. Its Build ISO component must not be run with its upstream
defaults: those defaults target a different distribution and profile source.

VENOM OS continues to use the official Manjaro `buildiso`, Calamares and
Manjaro package repositories. GitRepo validation is isolated from the Manjaro
build preflight until a compatible integration has been demonstrated.
