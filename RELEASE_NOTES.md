# Hypr-Lab v1.0 RC2 release notes

RC2 is the first release candidate prepared specifically from results of a
minimal-Arch virtual-machine installation test.

## Clean-install fixes

- Added a real clean-system login path using greetd + tuigreet +
  `start-hyprland`.
- Added `pipewire-jack` explicitly to remove the interactive JACK-provider
  question during pacman installation.
- Quickshell is now started after the Hypr-Lab XDG/session initialization
  script instead of racing that initialization.
- The first-login Welcome state is release-clean.
- The monitor-state database is reset for every new user install.
- The file-manager fallback is runtime-safe when no file manager is installed.

## Default Hypr-Lab desktop identity

- Custom `Bibata-Modern-Hypr-Lab` cursor, 24 px, black with cyan outline.
- `Fluent-teal-dark` icon theme.
- Theme attribution and GPL notices are documented in
  `THIRD_PARTY_NOTICES.md`.

## Intentionally not managed

- Hypr-Lab does not overwrite a user's Ghostty configuration.
- Hypr-Lab does not install or overwrite a Fastfetch configuration.
- Browser choice remains the XDG default.
