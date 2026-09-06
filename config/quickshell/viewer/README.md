# Hypr-Viewer

- `shell.qml` — viewer entry point
- `components/` — viewer-local QML components
- `assets/` — viewer assets such as the application icon
- `scripts/hypr-viewer.sh` — launcher that accepts files or folders
- `scripts/hypr-viewer-register.sh` — desktop/MIME registration

Run the registration script after copying the viewer:

```bash
chmod +x ~/.config/quickshell/viewer/scripts/*.sh
~/.config/quickshell/viewer/scripts/hypr-viewer-register.sh
```
