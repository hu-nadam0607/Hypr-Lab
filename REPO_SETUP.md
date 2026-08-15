# Hypr-Lab — Repository Setup / Repository kezelése

This document describes the basic repository and testing workflow used for Hypr-Lab development and release preparation.

Ez a dokumentum a Hypr-Lab fejlesztéséhez és a kiadások előkészítéséhez használt alapvető repository- és tesztelési folyamatot mutatja be.

---

# English

## Official repository

The official Hypr-Lab repository is:

```text
https://github.com/hu-nadam0607/Hypr-Lab
```

Clone it with:

```bash
git clone https://github.com/hu-nadam0607/Hypr-Lab.git
cd Hypr-Lab
```

## Local development workflow

Before making changes, check the current repository state:

```bash
git status
```

After making changes, inspect them before committing:

```bash
git diff
git status
```

Run the Hypr-Lab release verifier when working on release-related changes:

```bash
./verify-release.sh
```

If the verification succeeds, stage and commit the intended changes:

```bash
git add .
git status
git commit -m "Describe the change"
```

Push the commit to GitHub:

```bash
git push
```

## Git identity

If Git has not been configured with your identity yet:

```bash
git config --global user.name "YOUR_NAME"
git config --global user.email "YOUR_GITHUB_EMAIL"
```

Use the name and email address associated with your Git/GitHub workflow.

## Remote configuration

Check the configured remote:

```bash
git remote -v
```

The official repository uses:

```text
https://github.com/hu-nadam0607/Hypr-Lab.git
```

If a local clone does not yet have an `origin` remote:

```bash
git remote add origin https://github.com/hu-nadam0607/Hypr-Lab.git
```

For a new local repository, the main branch can be pushed with:

```bash
git push -u origin main
```

Existing clones can normally use:

```bash
git push
```

## VM testing workflow

A VM can be used to test installation and uninstall behavior without repeatedly copying release archives.

Clone the repository inside the VM:

```bash
git clone https://github.com/hu-nadam0607/Hypr-Lab.git
cd Hypr-Lab
```

After a host-side change has been committed and pushed, update the VM clone with:

```bash
cd ~/Hypr-Lab
git pull
```

Then run the installer again when required:

```bash
./install.sh
```

The uninstaller can be tested with:

```bash
./uninstall.sh
```

## Clean-install testing

For release validation, a clean or minimal Arch Linux environment should be used to verify that Hypr-Lab does not accidentally depend on packages, configuration or state from the developer's existing desktop.

Important areas to verify include:

* dependency installation;
* keyboard-layout substitution;
* Hyprland configuration deployment;
* Quickshell autostart;
* Welcome Screen release state;
* monitor release state;
* theme installation and ownership tracking;
* login-manager configuration and ownership tracking;
* backup creation;
* uninstall restoration;
* tracked package cleanup.

## VirtualBox limitation

VirtualBox is useful for testing the installer, package management, login-manager integration, Hyprland startup and uninstall workflow.

Its Qt/Wayland graphics behavior is not considered authoritative for complete Hypr-Lab visual validation.

Final visual behavior should be verified on real hardware.

## Release preparation

Before preparing a public release:

1. Review the intended changes with `git diff` and `git status`.
2. Run:

```bash
./verify-release.sh
```

3. Confirm that the verifier reports no release-blocking errors.
4. Commit the final release changes.
5. Push the final commit.
6. Update or freshly clone the repository in the clean test environment.
7. Perform the final installation and uninstall smoke test.
8. Confirm that the repository contains only the intended release files and state.
9. Create the public release only after the final release review is complete.

---

# Magyar

## Hivatalos repository

A Hypr-Lab hivatalos repositoryja:

```text
https://github.com/hu-nadam0607/Hypr-Lab
```

Klónozás:

```bash
git clone https://github.com/hu-nadam0607/Hypr-Lab.git
cd Hypr-Lab
```

## Helyi fejlesztési folyamat

Módosítás előtt ellenőrizd a repository aktuális állapotát:

```bash
git status
```

A módosítások elvégzése után commit előtt ellenőrizd őket:

```bash
git diff
git status
```

Release-hez kapcsolódó módosítások esetén futtasd a Hypr-Lab release verifierét:

```bash
./verify-release.sh
```

Ha az ellenőrzés sikeres, add hozzá és commitold a kívánt módosításokat:

```bash
git add .
git status
git commit -m "A módosítás leírása"
```

Ezután pushold a commitot GitHubra:

```bash
git push
```

## Git identitás

Ha a Git még nincs beállítva a saját neveddel és e-mail-címeddel:

```bash
git config --global user.name "SAJÁT_NÉV"
git config --global user.email "SAJÁT_GITHUB_EMAIL"
```

A saját Git/GitHub munkafolyamatodhoz tartozó nevet és e-mail-címet használd.

## Remote beállítása

Az aktuális remote ellenőrzése:

```bash
git remote -v
```

A hivatalos repository címe:

```text
https://github.com/hu-nadam0607/Hypr-Lab.git
```

Ha egy helyi repository még nem rendelkezik `origin` remote-tal:

```bash
git remote add origin https://github.com/hu-nadam0607/Hypr-Lab.git
```

Új helyi repository esetén a main branch első push-a:

```bash
git push -u origin main
```

Már beállított clone esetén általában elegendő:

```bash
git push
```

## VM-es tesztelési folyamat

Virtuális gép használható a telepítés és eltávolítás tesztelésére anélkül, hogy minden módosítás után új release archívumot kellene másolni.

Klónozd a repositoryt a VM-en:

```bash
git clone https://github.com/hu-nadam0607/Hypr-Lab.git
cd Hypr-Lab
```

Miután a fő gépen elvégzett módosítást commitoltad és pusholtad, a VM repositoryját így frissítheted:

```bash
cd ~/Hypr-Lab
git pull
```

Ezután szükség esetén ismét futtatható a telepítő:

```bash
./install.sh
```

Az eltávolító tesztelése:

```bash
./uninstall.sh
```

## Tiszta telepítés tesztelése

Release ellenőrzéséhez tiszta vagy minimális Arch Linux környezet használata ajánlott. Ezzel ellenőrizhető, hogy a Hypr-Lab véletlenül sem függ a fejlesztő meglévő rendszerén található csomagoktól, konfigurációktól vagy állapotfájloktól.

Kiemelten ellenőrizendő területek:

* függőségek telepítése;
* billentyűzetkiosztás behelyettesítése;
* Hyprland konfiguráció telepítése;
* Quickshell autostart;
* Welcome Screen release state;
* monitor release state;
* témák telepítése és ownership-követése;
* login manager konfigurációja és ownership-követése;
* biztonsági mentés létrehozása;
* uninstall utáni visszaállítás;
* nyomon követett csomagok eltávolítása.

## VirtualBox korlátozás

A VirtualBox jól használható az installer, a csomagkezelés, a login-manager integráció, a Hyprland indulása és az uninstall folyamat tesztelésére.

A Qt/Wayland grafikus működését azonban nem tekintjük mérvadónak a Hypr-Lab teljes vizuális ellenőrzéséhez.

A végleges vizuális működést valódi hardveren érdemes ellenőrizni.

## Release előkészítése

Nyilvános kiadás előkészítése előtt:

1. Ellenőrizd a tervezett módosításokat a `git diff` és `git status` segítségével.
2. Futtasd:

```bash
./verify-release.sh
```

3. Ellenőrizd, hogy a verifier nem jelez release-t blokkoló hibát.
4. Commitold a végleges release-módosításokat.
5. Pushold a végleges commitot.
6. Frissítsd vagy klónozd újra a repositoryt a tiszta tesztkörnyezetben.
7. Végezd el a végső telepítési és eltávolítási smoke tesztet.
8. Ellenőrizd, hogy a repository kizárólag a kívánt release-fájlokat és állapotot tartalmazza.
9. A public release csak a végső release-ellenőrzés után készüljön el.
