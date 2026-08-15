# Hypr-Lab 1.0 — Release Notes / Kiadási megjegyzések

Hypr-Lab 1.0 is the first stable release of the Hypr-Lab desktop experience for Arch Linux, Hyprland and Quickshell.

A Hypr-Lab 1.0 a Hypr-Lab Arch Linuxra, Hyprlandre és Quickshellre épülő asztali környezetének első stabil kiadása.

---

# English

## Hypr-Lab 1.0

Version 1.0 brings together the Hypr-Lab desktop shell, its installation workflow, safe configuration handling and reversible uninstall process into the first stable release.

The release was prepared and tested with particular attention to clean Arch Linux installations, existing user configuration, package ownership and safe removal.

## Desktop experience

Hypr-Lab 1.0 includes:

* Hypr-Lab Top Bar;
* workspace controls;
* Center Island;
* App Launcher;
* Control Center;
* advanced audio controls and output-device selection;
* media controls and visualization;
* Notification Center;
* Do Not Disturb mode;
* USB Manager;
* Wallpaper Manager;
* animated wallpaper transitions;
* wallpaper picker;
* custom Lock Screen;
* Welcome Screen;
* Power Menu;
* Hypr-Lab Settings;
* monitor configuration tools;
* screenshot shortcuts;
* custom Hypr-Lab visual styling.

## Default visual integration

Hypr-Lab 1.0 installs and configures:

* `Bibata-Modern-Hypr-Lab` cursor;
* cursor size `24`;
* black cursor interior with Hypr-Lab cyan `#37F5EB` outline;
* `Fluent-teal-dark` icon theme;
* optional Hypr-Lab GTK3/GTK4 CSS integration.

Third-party theme sources retain their original licensing. See `THIRD_PARTY_NOTICES.md`.

## Installation

Hypr-Lab provides an interactive installer:

```bash
./install.sh
```

On a clean Arch Linux installation, the installer can install the required missing packages and configure the default login path:

```text
greetd -> tuigreet -> start-hyprland -> Hyprland -> Hypr-Lab
```

The installer:

* detects missing dependencies;
* records packages installed by Hypr-Lab;
* preserves existing Hypr-Lab-related user configuration through backups when applicable;
* installs the Hyprland and Quickshell configuration payload;
* replaces the keyboard-layout placeholder with the selected layout;
* configures browser launching through the user's XDG default;
* detects supported installed file managers;
* installs the Hypr-Lab cursor and Fluent teal icons;
* can install Hypr-Lab GTK integration;
* can configure `greetd` and `tuigreet`;
* keeps release state clean for first startup.

The installer must be run as a normal user and requests `sudo` only when system-level changes are required.

## Safe uninstall

Hypr-Lab 1.0 includes a tracked and reversible uninstaller:

```bash
./uninstall.sh
```

The uninstaller can:

* remove Hypr-Lab user configuration;
* restore a recorded pre-Hypr-Lab configuration backup;
* restore previous cursor and icon settings;
* remove themes only when they were recorded as installed and managed by Hypr-Lab;
* restore Hypr-Lab-managed login-manager state;
* optionally remove packages recorded as installed by Hypr-Lab;
* optionally remove installer state and backups.

Hypr-Lab does not guess package or theme ownership.

Packages or themes that existed before Hypr-Lab are not treated as Hypr-Lab-owned merely because Hypr-Lab also uses them.

Package removal uses the recorded installer state and normal `pacman -Rns` dependency resolution.

The cloned source/release directory itself is deliberately not deleted by the uninstaller.

## Release-safety improvements

The final 1.0 release includes fixes and safeguards discovered during release-candidate testing:

* Quickshell autostart is present in the release Hyprland Lua payload;
* the generic `__HYPRLAB_KB_LAYOUT__` marker is replaced by the installer with the selected keyboard layout;
* the release payload is checked for unresolved keyboard-layout placeholders;
* clean-install login uses `greetd`, `tuigreet` and `start-hyprland`;
* `pipewire-jack` is explicitly included to avoid an interactive JACK-provider choice during dependency installation;
* Welcome Screen state is release-clean;
* monitor state starts clean;
* Hypr-Lab-installed package ownership is recorded;
* Hypr-Lab-managed theme ownership is recorded;
* login-manager ownership/state is recorded before changes are made;
* uninstall avoids modifying packages, themes or login-manager state without recorded ownership information.

## Release verification

The release verifier checks critical release properties before publication, including:

* installer and uninstaller shell syntax;
* absence of hardcoded `/home/<user>` paths;
* obsolete helper references;
* release-clean Welcome state;
* keyboard-layout placeholder state;
* clean monitor state;
* Quickshell autostart;
* release script versions;
* tracked dependency uninstall support.

## Installation and uninstall testing

The 1.0 release workflow was tested through a complete lifecycle:

```text
clean/minimal Arch
        ->
Hypr-Lab install
        ->
reboot
        ->
greetd / tuigreet
        ->
start-hyprland
        ->
Hyprland
        ->
Quickshell launch attempt
        ->
Hypr-Lab uninstall
        ->
pre-Hypr-Lab state
```

The test confirmed installer deployment, keyboard-layout substitution, Quickshell autostart invocation, package ownership tracking, theme ownership tracking, login-manager integration and cleanup, package cleanup, configuration cleanup and installer-state cleanup.

## VirtualBox graphics note

VirtualBox was used successfully for installer, package-management, `greetd`, Hyprland Lua, login-chain and uninstall testing.

During VM testing, Quickshell successfully launched and loaded the Hypr-Lab configuration, but the VirtualBox Qt/Wayland graphics path could terminate with EGL/Wayland surface errors.

Because of this, VirtualBox graphics behavior is not considered authoritative for final Hypr-Lab visual rendering.

Visual behavior is intended to be validated on real hardware.

---

# Magyar

## Hypr-Lab 1.0

Az 1.0 verzió a Hypr-Lab asztali shellt, a telepítési folyamatot, a biztonságos konfigurációkezelést és a visszafordítható eltávolítási folyamatot egyesíti az első stabil kiadásban.

A kiadás előkészítése és tesztelése során kiemelt figyelmet kapott a tiszta Arch Linux telepítés, a meglévő felhasználói konfigurációk megőrzése, a csomagok tulajdonosi állapotának kezelése és a biztonságos eltávolítás.

## Asztali környezet

A Hypr-Lab 1.0 többek között a következőket tartalmazza:

* Hypr-Lab Top Bar;
* munkaterület-vezérlés;
* Center Island;
* App Launcher;
* Control Center;
* fejlett hangvezérlés és hangkimenet-választás;
* médiavezérlés és vizualizáció;
* Notification Center;
* Ne zavarjanak mód;
* USB Manager;
* Wallpaper Manager;
* animált háttérkép-átmenetek;
* háttérképválasztó;
* egyedi Lock Screen;
* Welcome Screen;
* Power Menu;
* Hypr-Lab Settings;
* monitorkonfigurációs eszközök;
* képernyőkép-gyorsbillentyűk;
* egyedi Hypr-Lab vizuális megjelenés.

## Alapértelmezett vizuális integráció

A Hypr-Lab 1.0 telepíti és konfigurálja:

* a `Bibata-Modern-Hypr-Lab` kurzort;
* `24`-es kurzorméretet;
* fekete belső színt Hypr-Lab cyan `#37F5EB` körvonallal;
* a `Fluent-teal-dark` ikontémát;
* opcionális Hypr-Lab GTK3/GTK4 CSS integrációt.

A harmadik féltől származó témák megtartják eredeti licencfeltételeiket. Részletek a `THIRD_PARTY_NOTICES.md` fájlban.

## Telepítés

A Hypr-Lab interaktív telepítőt biztosít:

```bash
./install.sh
```

Tiszta Arch Linux telepítés esetén a telepítő képes feltelepíteni a szükséges hiányzó csomagokat és konfigurálni az alapértelmezett bejelentkezési folyamatot:

```text
greetd -> tuigreet -> start-hyprland -> Hyprland -> Hypr-Lab
```

A telepítő:

* felismeri a hiányzó függőségeket;
* rögzíti a Hypr-Lab által telepített csomagokat;
* szükség esetén biztonsági mentéssel megőrzi a Hypr-Lab által érintett meglévő felhasználói konfigurációt;
* telepíti a Hyprland és Quickshell konfigurációs payloadot;
* a billentyűzetkiosztás placeholderét a kiválasztott kiosztásra cseréli;
* a böngésző indítását a felhasználó XDG alapértelmezéséhez igazítja;
* felismeri a támogatott telepített fájlkezelőket;
* telepíti a Hypr-Lab kurzort és a Fluent teal ikonokat;
* képes telepíteni a Hypr-Lab GTK integrációját;
* képes konfigurálni a `greetd` és `tuigreet` használatát;
* tiszta release state-et biztosít az első induláshoz.

A telepítőt normál felhasználóként kell futtatni. `sudo` jogosultságot csak a rendszerszintű módosításokhoz kér.

## Biztonságos eltávolítás

A Hypr-Lab 1.0 nyomon követett és visszafordítható eltávolítót tartalmaz:

```bash
./uninstall.sh
```

Az uninstaller képes:

* eltávolítani a Hypr-Lab felhasználói konfigurációját;
* visszaállítani a rögzített, Hypr-Lab előtti konfiguráció biztonsági mentését;
* visszaállítani a korábbi kurzor- és ikonbeállításokat;
* kizárólag akkor eltávolítani témákat, ha azok Hypr-Lab által telepítettként és kezeltként lettek rögzítve;
* visszaállítani a Hypr-Lab által kezelt login-manager állapotot;
* opcionálisan eltávolítani a Hypr-Lab által telepítettként rögzített csomagokat;
* opcionálisan eltávolítani a telepítő állapotfájljait és biztonsági mentéseit.

A Hypr-Lab nem próbálja kitalálni a csomagok vagy témák tulajdonjogát.

Azok a csomagok vagy témák, amelyek már a Hypr-Lab előtt is léteztek, nem válnak automatikusan Hypr-Lab-tulajdonná csak azért, mert a Hypr-Lab is használja őket.

A csomagok eltávolítása a telepítő által rögzített állapotot és a `pacman -Rns` normál függőségkezelését használja.

A klónozott forrás-/release-könyvtárat az uninstaller szándékosan nem törli.

## Release-biztonsági fejlesztések

A végleges 1.0 kiadás tartalmazza a release candidate tesztelés során feltárt javításokat és biztonsági megoldásokat:

* a Quickshell autostart jelen van a release Hyprland Lua payloadban;
* az általános `__HYPRLAB_KB_LAYOUT__` markert a telepítő a kiválasztott billentyűzetkiosztásra cseréli;
* a release payload ellenőrzésre kerül feloldatlan billentyűzetkiosztás-placeholderek szempontjából;
* a tiszta telepítés bejelentkezési folyamata `greetd`, `tuigreet` és `start-hyprland` használatára épül;
* a `pipewire-jack` explicit függőségként szerepel, így a csomagtelepítés közben nincs szükség interaktív JACK-provider választásra;
* a Welcome Screen state release-clean állapotból indul;
* a monitor state tiszta állapotból indul;
* a Hypr-Lab által telepített csomagok tulajdonosi állapota rögzítésre kerül;
* a Hypr-Lab által kezelt témák tulajdonosi állapota rögzítésre kerül;
* a login manager tulajdonosi/állapotinformációja a módosítás előtt rögzítésre kerül;
* az uninstaller rögzített ownership információ nélkül nem módosít csomagokat, témákat vagy login-manager állapotot.

## Release ellenőrzése

A release verifier publikálás előtt ellenőrzi a kritikus release-tulajdonságokat, többek között:

* az installer és uninstaller shell szintaxisát;
* a hardcoded `/home/<user>` útvonalak hiányát;
* az elavult helper hivatkozásokat;
* a Welcome release-clean állapotát;
* a billentyűzetkiosztás placeholder állapotát;
* a tiszta monitor state-et;
* a Quickshell autostartot;
* a release scriptek verzióit;
* a nyomon követett dependency uninstall támogatását.

## Telepítési és eltávolítási teszt

Az 1.0 kiadási folyamat teljes életcikluson keresztül lett tesztelve:

```text
tiszta/minimális Arch
        ->
Hypr-Lab telepítés
        ->
újraindítás
        ->
greetd / tuigreet
        ->
start-hyprland
        ->
Hyprland
        ->
Quickshell indítási kísérlet
        ->
Hypr-Lab eltávolítás
        ->
Hypr-Lab előtti állapot
```

A teszt igazolta az installer deploymentet, a billentyűzetkiosztás behelyettesítését, a Quickshell autostart meghívását, a csomag- és téma-ownership nyomon követését, a login-manager integrációját és eltávolítását, a csomagok eltávolítását, a konfiguráció eltávolítását és az installer-state takarítását.

## VirtualBox grafikai megjegyzés

A VirtualBox sikeresen használható volt az installer, a csomagkezelés, a `greetd`, a Hyprland Lua, a login chain és az uninstall tesztelésére.

A VM-es tesztelés során a Quickshell sikeresen elindult és betöltötte a Hypr-Lab konfigurációját, azonban a VirtualBox Qt/Wayland grafikus útvonala EGL/Wayland surface hibákkal leállhatott.

Emiatt a VirtualBox grafikus viselkedését nem tekintjük mérvadónak a Hypr-Lab végleges vizuális renderelésének megítélésében.

A vizuális működés végleges ellenőrzésére valódi hardver szolgál.
