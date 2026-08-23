# Hypr-Lab 1.5

Hypr-Lab is my Arch Linux + Hyprland desktop setup, built around Quickshell. It started as a personal configuration and gradually turned into a complete shell with its own top bar, launcher, settings, lock screen, control panels and wallpaper tools.

A Hypr-Lab az Arch Linux + Hyprland rendszeremhez készült saját desktop setupom, Quickshell alapokon. Személyes konfigurációként indult, majd idővel komplett shell lett belőle saját felső sávval, launcherrel, beállításokkal, lock screennel, vezérlőpanelekkel és háttérképkezeléssel.

![Hypr-Lab Desktop](docs/screenshots/HL15_FS_.png)

---

## Hypr-Lab 1.5 — development branch / fejlesztői ág

**Hypr-Lab 1.0 is still the current stable release.** Version 1.5 is being developed on the `develop-v1.5` branch.

**A Hypr-Lab 1.0 továbbra is a jelenlegi stabil kiadás.** Az 1.5-ös verzió fejlesztése a `develop-v1.5` ágon történik.

**Current milestone / Jelenlegi mérföldkő: v1.5 RC3**

RC3 is the current working state of the 1.5 branch. Most of the shell has already been rebuilt for 1.5, but this is still a development branch, so changes can land before the final release.

Az RC3 az 1.5-ös ág jelenlegi működő állapota. A shell nagy része már az új 1.5-ös rendszerre épül, de ez továbbra is fejlesztői ág, ezért a végleges kiadásig még változhat.

---

## What is in 1.5? / Mi van az 1.5-ben?

### English

The 1.5 branch is a major rebuild rather than a small update. The current version includes:

- one unified Hypr-Lab Top Bar with workspaces, Center Island and system controls;
- configurable workspace count from 1 to 10, with navigation limited to the enabled workspaces;
- configurable Top Bar modules and Center Island feedback;
- wallpaper-adaptive accent colors;
- 4×4 App Launcher with search, mouse control and keyboard navigation;
- Control Center with theme, tools, media and system actions;
- separate Audio Control with output-device selection and volume controls;
- Notification Center and Do Not Disturb mode;
- USB Manager with mount, unmount and safe eject actions;
- animated Wallpaper Manager and horizontal Wallpaper Picker;
- custom Lock Screen with media/CAVA dock;
- automatic lock, display standby and suspend handling;
- Hypr-Lab Settings for appearance, desktop, Top Bar, lock/power and other shell options;
- monitor configuration tools;
- screenshot shortcuts;
- custom Hypr-Lab cursor and Fluent teal icon theme;
- installer backups and a matching uninstaller.

### Magyar

Az 1.5 nem egy kisebb frissítés, hanem a Hypr-Lab jelentős átdolgozása. A jelenlegi verzióban már működik:

- az egységes Hypr-Lab Top Bar workspace-ekkel, Center Islanddel és rendszervezérlőkkel;
- 1 és 10 között állítható workspace-mennyiség, ahol a navigáció is a ténylegesen engedélyezett workspace-ekre korlátozódik;
- külön kapcsolható Top Bar modulok és Center Island visszajelzések;
- a háttérképhez automatikusan igazodó accent szín;
- 4×4-es App Launcher kereséssel, egér- és billentyűzetes vezérléssel;
- Control Center téma-, eszköz-, média- és rendszerműveletekkel;
- külön Audio Control hangkimenet-választással és hangerőszabályzással;
- Notification Center és Ne zavarjanak mód;
- USB Manager mount, unmount és biztonságos leválasztási funkciókkal;
- animált Wallpaper Manager és vízszintes Wallpaper Picker;
- saját Lock Screen media/CAVA dockkal;
- automatikus képernyőzár, kijelző-készenlét és rendszer-altatás;
- Hypr-Lab Settings az appearance, desktop, Top Bar, lock/power és további shell beállításokhoz;
- monitorkonfigurációs eszközök;
- screenshot gyorsbillentyűk;
- saját Hypr-Lab kurzor és Fluent teal ikontéma;
- telepítés előtti backup és hozzá tartozó uninstaller.

---

## Screenshots / Képernyőképek

### Desktop

![Hypr-Lab Desktop](docs/screenshots/HL15_FS_.png)

### Hypr-Lab Settings

![Hypr-Lab Settings](docs/screenshots/HL15_SET.png)

### Control Center

![Hypr-Lab Control Center](docs/screenshots/HL15_CC.png)

### Audio Control

![Hypr-Lab Audio Control](docs/screenshots/HL15_AC.png)

### App Launcher

![Hypr-Lab App Launcher](docs/screenshots/HL15_LNCH.png)

### Notification Center

![Hypr-Lab Notification Center](docs/screenshots/HL15_NC.png)

### Wallpaper Picker

![Hypr-Lab Wallpaper Picker](docs/screenshots/HL15_WPP.png)

### Power Menu

![Hypr-Lab Power Menu](docs/screenshots/HL15_PM.png)

---

## Requirements / Követelmények

Hypr-Lab currently targets:

- Arch Linux;
- Hyprland 0.55+ with the Lua configuration model;
- Wayland;
- Quickshell;
- PipeWire + WirePlumber.

A Hypr-Lab jelenlegi célrendszere:

- Arch Linux;
- Hyprland 0.55+ Lua konfigurációs modellel;
- Wayland;
- Quickshell;
- PipeWire + WirePlumber.

The installer checks the required Arch packages and can install the missing ones.

A telepítő ellenőrzi a szükséges Arch csomagokat, és igény esetén telepíti a hiányzókat.

---

# Quick Install / Gyors telepítés

## English

Clone the repository and run the installer as your **normal user**:

```bash
git clone https://github.com/hu-nadam0607/Hypr-Lab.git
cd Hypr-Lab
./install.sh
```

Do **not** run `install.sh` as root. It asks for `sudo` only when a system-level change is needed.

After the installer finishes, reboot the machine. On a clean Arch installation the normal login path is:

```text
greetd -> tuigreet -> start-hyprland -> Hyprland -> Hypr-Lab
```

If login-manager setup was skipped, Hyprland can also be started from a TTY:

```bash
start-hyprland
```

## Magyar

Klónozd a repositoryt, majd **normál felhasználóként** indítsd el a telepítőt:

```bash
git clone https://github.com/hu-nadam0607/Hypr-Lab.git
cd Hypr-Lab
./install.sh
```

Az `install.sh` fájlt **ne rootként** futtasd. A telepítő csak akkor kér `sudo` jogosultságot, amikor valóban rendszerszintű módosításra van szükség.

A telepítés végén indítsd újra a gépet. Tiszta Arch telepítésnél az alapértelmezett bejelentkezési folyamat:

```text
greetd -> tuigreet -> start-hyprland -> Hyprland -> Hypr-Lab
```

Ha a login manager beállítását kihagytad, Hyprland TTY-ből is indítható:

```bash
start-hyprland
```

---

# Quick Uninstall / Gyors eltávolítás

## English

From the cloned Hypr-Lab directory run:

```bash
./uninstall.sh
```

By default the uninstaller removes the Hypr-Lab user configuration, restores the pre-install backup when one exists, removes Hypr-Lab-owned themes and restores the login integration managed by Hypr-Lab. Arch packages are kept unless their removal is explicitly approved. The cloned repository itself is not deleted.

Full purge:

```bash
./uninstall.sh --purge
```

Non-interactive full purge:

```bash
./uninstall.sh --purge --yes
```

## Magyar

A klónozott Hypr-Lab könyvtárban futtasd:

```bash
./uninstall.sh
```

Alapértelmezetten az uninstaller eltávolítja a Hypr-Lab felhasználói konfigurációját, visszaállítja a telepítés előtti backupot, ha van ilyen, eltávolítja a Hypr-Labhoz tartozó témákat, és visszaállítja a Hypr-Lab által kezelt login integrációt. Az Arch csomagok megmaradnak, hacsak külön nem hagyod jóvá az eltávolításukat. Magát a klónozott repositoryt az uninstaller nem törli.

Teljes eltávolítás:

```bash
./uninstall.sh --purge
```

Nem interaktív teljes eltávolítás:

```bash
./uninstall.sh --purge --yes
```

---

## Package handling / Csomagkezelés

The installer records packages that were missing before Hypr-Lab and were installed by the installer. The uninstaller can offer only those recorded packages for removal. Packages that were already present on the system are not treated as Hypr-Lab-owned. Package removal itself is handled by `pacman -Rns` with its normal dependency checks.

A telepítő feljegyzi azokat a csomagokat, amelyek a Hypr-Lab előtt nem voltak a rendszeren, és amelyeket maga a telepítő rakott fel. Az uninstaller csak ezeket tudja eltávolításra felajánlani. A korábban is telepített csomagokat nem kezeli Hypr-Lab-tulajdonként. A tényleges csomageltávolítást a `pacman -Rns` végzi a szokásos függőségellenőrzéssel.

---

## Installer options / Telepítő opciók

```text
-y, --yes            Accept normal prompts automatically
                     Normál kérdések automatikus elfogadása

--skip-deps          Skip Arch package installation/checks
                     Arch csomagok ellenőrzésének/telepítésének kihagyása

--no-gtk             Do not install Hypr-Lab GTK CSS
                     Hypr-Lab GTK CSS telepítésének kihagyása

--no-themes          Do not install the Hypr-Lab cursor and Fluent icons
                     Hypr-Lab kurzor és Fluent ikonok telepítésének kihagyása

--no-login-manager   Do not configure greetd/tuigreet
                     A greetd/tuigreet konfigurálásának kihagyása

-h, --help           Show help / Súgó
```

## Uninstaller options / Eltávolító opciók

```text
-y, --yes       Accept safe default prompts automatically
                Biztonságos alapértelmezett válaszok automatikus elfogadása

--purge         Remove tracked packages and Hypr-Lab state/backups too
                Rögzített csomagok és a Hypr-Lab state/backup eltávolítása

--purge-deps    Remove packages recorded as installed by Hypr-Lab
                A Hypr-Lab által telepítettként rögzített csomagok eltávolítása

--purge-state   Remove ~/.local/state/hypr-lab after uninstall
                A ~/.local/state/hypr-lab eltávolítása az uninstall után

--no-restore    Do not restore the pre-Hypr-Lab configuration backup
                Ne állítsa vissza a Hypr-Lab előtti konfigurációt

--keep-login    Leave greetd/display-manager integration untouched
                A greetd/display-manager integráció érintetlenül hagyása

-h, --help      Show help / Súgó
```

---

## Default themes / Alapértelmezett témák

### Cursor / Kurzor

Hypr-Lab builds its Bibata-based cursor locally during installation:

A Hypr-Lab telepítés közben helyben építi fel a Bibata-alapú kurzort:

```text
Bibata-Modern-Hypr-Lab
size / méret: 24
inside / belső szín: black / fekete
outline / körvonal: #37F5EB
```

The cursor is built from the upstream Bibata Modern SVG sources. Licensing details are in `THIRD_PARTY_NOTICES.md`.

A kurzor az upstream Bibata Modern SVG forrásaira épül. A licencinformációk a `THIRD_PARTY_NOTICES.md` fájlban találhatók.

### Icons / Ikonok

The installer uses the upstream Fluent icon theme and selects:

A telepítő az upstream Fluent ikontémát használja, alapértelmezetten ezzel a változattal:

```text
Fluent-teal-dark
```

The theme remains a separate upstream project. See `THIRD_PARTY_NOTICES.md` for details.

Az ikontéma továbbra is külön upstream projekt. Részletek a `THIRD_PARTY_NOTICES.md` fájlban.

---

## Main dependencies / Fő függőségek

The desktop stack uses official Arch packages where possible. The main pieces are Hyprland, Quickshell, Ghostty, PipeWire, WirePlumber, Hypridle, Hyprpolkitagent, XDG portals, screenshot/media tools, fonts, `greetd` and `greetd-tuigreet`.

A desktop stack lehetőség szerint hivatalos Arch csomagokra épül. A fő elemek: Hyprland, Quickshell, Ghostty, PipeWire, WirePlumber, Hypridle, Hyprpolkitagent, XDG portalok, screenshot- és médiaeszközök, betűtípusok, `greetd` és `greetd-tuigreet`.

Hypr-Lab does not force a specific browser or file manager. Browser launching follows the XDG default. Supported installed file managers are detected automatically.

A Hypr-Lab nem kényszerít rád konkrét böngészőt vagy fájlkezelőt. A böngésző az XDG alapértelmezést követi, a támogatott telepített fájlkezelőket pedig a rendszer automatikusan felismeri.

Theme installation also uses Git, Yarn/npm and pipx to build the Hypr-Lab Bibata variant from upstream source.

A témák telepítéséhez Git, Yarn/npm és pipx is szükséges, mert a Hypr-Lab Bibata változata upstream forrásból épül.

---

## Main shortcuts / Fő gyorsbillentyűk

| Shortcut / Gyorsbillentyű | Action / Művelet |
| --- | --- |
| `SUPER + SPACE` | App Launcher / Alkalmazásindító |
| `SUPER + SHIFT + C` | Control Center / Vezérlőközpont |
| `SUPER + SHIFT + V` | Audio Control / Hangvezérlés |
| `SUPER + SHIFT + N` | Notification Center / Értesítési központ |
| `SUPER + SHIFT + D` | Do Not Disturb / Ne zavarjanak |
| `SUPER + SHIFT + W` | Wallpaper Picker / Háttérképválasztó |
| `SUPER + W` | Random wallpaper / Véletlenszerű háttérkép |
| `SUPER + I` | Hypr-Lab Settings / Beállítások |
| `SUPER + L` | Lock Screen / Képernyőzár |
| `SUPER + ALT + W` | Welcome Screen / Üdvözlőképernyő |
| `SUPER + SHIFT + P` | Power Menu / Kikapcsolási menü |
| `SUPER + C` | Ghostty |
| `SUPER + E` | Selected/detected file manager / Kiválasztott vagy felismert fájlkezelő |
| `SUPER + B` | XDG default browser / XDG alapértelmezett böngésző |
| `SUPER + M` | Exit Hyprland session / Kilépés a Hyprland munkamenetből |
| `SUPER + 1…0` | Workspace 1…10, limited by Settings / Workspace 1…10, a Settingsben megadott limit szerint |

---

## Backups / Biztonsági mentések

Before replacing an existing Hypr-Lab-related user configuration, the installer creates a backup when needed:

A meglévő, Hypr-Lab által érintett felhasználói konfiguráció cseréje előtt a telepítő szükség esetén backupot készít:

```text
~/.local/state/hypr-lab/backups/<timestamp>/
```

The latest backup path is stored in:

A legutóbbi backup helyét ez a fájl tárolja:

```text
~/.local/state/hypr-lab/last-backup
```

The uninstaller uses this information when restoring the configuration that existed before Hypr-Lab.

Az uninstaller ezt az információt használja a Hypr-Lab előtti konfiguráció visszaállításához.

---

## Repository layout / Repository felépítése

```text
Hypr-Lab/
├── config/
│   ├── hypr/
│   ├── quickshell/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   └── wireplumber/
├── docs/
│   └── screenshots/
├── system/
│   └── greetd/
│       └── config.toml
├── install.sh
├── uninstall.sh
├── verify-release.sh
├── manifest.json
├── README.md
├── RELEASE_NOTES.md
├── THIRD_PARTY_NOTICES.md
└── LICENSE
```

`config/` contains the user configuration installed by Hypr-Lab. `system/` contains the system-level templates used when required. Project screenshots live in `docs/screenshots/`. The installer and uninstaller are kept in the repository root together with release metadata and licensing files.

A `config/` tartalmazza a Hypr-Lab által telepített felhasználói konfigurációt. A `system/` alatt vannak a szükség esetén használt rendszerszintű sablonok. A projekt képernyőképei a `docs/screenshots/` könyvtárban találhatók. A telepítő, az uninstaller, a release metaadatok és a licencfájlok a repository gyökerében vannak.

---

## License and credits / Licenc és közreműködők

Hypr-Lab is released under the **GNU General Public License v3.0** and is maintained by **nadam0607**. Third-party components keep their own copyright and licensing terms; see `THIRD_PARTY_NOTICES.md` for the details.

A Hypr-Lab a **GNU General Public License v3.0** alatt jelenik meg, karbantartója **nadam0607**. A harmadik féltől származó komponensek saját szerzői jogi és licencfeltételeiket tartják meg; a részleteket a `THIRD_PARTY_NOTICES.md` tartalmazza.
