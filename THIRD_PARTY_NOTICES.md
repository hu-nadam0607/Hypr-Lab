# Third-party notices

Hypr-Lab is distributed under the GNU GPL v3.0. It integrates with and can
install third-party open-source projects which retain their own copyrights and
licenses.

## Bibata Cursor

- Project: Bibata Cursor
- Upstream: `ful1e5/Bibata_Cursor` (installer pins release `v2.0.7`)
- Copyright: Abdulkaiz Khatri and contributors
- License: GNU GPL v3.0 (the upstream license text also states GPL v3 or later)
- Hypr-Lab modification: the installer generates `Bibata-Modern-Hypr-Lab`
  locally from the upstream Modern SVG sources with a black fill and Hypr-Lab
  cyan outline (`#37F5EB`).

The Bibata source is fetched from upstream at install time; Hypr-Lab does not
claim authorship of Bibata.

## Fluent Icon Theme

- Project: Fluent icon theme
- Upstream: `vinceliuice/Fluent-icon-theme` (installer pins release `2026-07-27`)
- Copyright: Vince Liuice and contributors
- License: GNU GPL v3.0
- Hypr-Lab default: `Fluent-teal-dark` when available.

The Fluent source is fetched from upstream at install time; Hypr-Lab does not
claim authorship of Fluent.

## Hyprland, Quickshell and the Arch Linux packages

Hypr-Lab depends on Hyprland, Quickshell and additional Arch Linux packages.
They are separate projects and remain under their respective licenses.

## Development note

Hypr-Lab was created by nadam0607 as a personal Arch/Hyprland project and was
developed with assistance from OpenAI ChatGPT. AI assistance included code
drafting, debugging, refactoring and installer/test workflow support. Project
direction, testing and release decisions remain with the project maintainer.
