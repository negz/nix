# CRUSH.md

This file provides guidance for agentic coding tools working with this NixOS configuration repository.

## Build/Apply Commands
```bash
# Build specific configuration
nix build .#nixosConfigurations.mael.config.system.build.toplevel
nix build .#darwinConfigurations.bugg.system

# Apply configuration (includes Home Manager)
sudo nixos-rebuild switch --flake .#mael
darwin-rebuild switch --flake .#bugg

# Test without switching
sudo nixos-rebuild test --flake .#mael
darwin-rebuild check --flake .#bugg

# Update flake inputs
nix flake update

# Show available outputs
nix flake show

# Check flake for errors
nix flake check
```

## Code Style Guidelines

### Nix Language Patterns
- Use attribute sets for configuration organization
- Prefer `with pkgs; [...]` for package lists
- Use `lib.mkIf` for conditional configurations
- Leverage `let ... in` for local variable definitions

### Naming Conventions
- Use kebab-case for attribute names
- Use descriptive, specific names for configurations
- Follow existing patterns in `hosts/` and `users/` directories

### Imports and Structure
- Keep system configurations in `hosts/<hostname>/configuration.nix`
- User configurations in `users/negz/configuration.nix`
- Custom packages in `pkgs/` following nixpkgs conventions
- Use stable channels as base, access unstable via `pkgs.unstable`

### Error Handling
- Always test configurations with `nixos-rebuild test` or `darwin-rebuild check`
- Use `nix flake check` to validate flake integrity
- Verify changes before system-wide application