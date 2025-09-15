# NFC 2 Click sa DE1-SoC pločom

Konfiguracija DE1-SoC ploče koja omogućava upotrebu NFC 2 Click ploče na Linux operativnom sistemu.

## Buildroot

Kao alat za automatizaciju procesa izgradnje svih potrebnih komponenti za pokretanje Linux jezgra na ploči i upotrebu NFC 2 Click ploče sa PN7150 modulom, korišten je Buildroot projekat. Svi fajlovi potrebni za konfiguraciju Buildroot projekta smješteni su unutar *buildroot* foldera u okviru ovog repozitorijuma.

Korištena verzija Buildroot-a je 2024.02.

Kao početna konfiguracija preporučuje se upotreba konfiguracije *buildroot/configs/de1soc_defconfig*. Nakon selektovanja ove konfiguracije potrebno je promijeniti putanju do Toolchain-a.

## Drajver
Prije kompajliranja kernela potrebno je ubaciti drajver za PN7150 koji se nalazi u folderu *nxp-pn5xx*. Drajver je modifikovan tako da su popravljene određene kompajlerske greške.
Uputstvo za ubacivanje drajvera je dostupno na [ovom](https://www.nxp.com/docs/en/application-note/AN11697.pdf) linku.
Drajver je ubačen kao modul u defconfig fajlu kernela koji se nalazi u folderu *buildroot/board/terasic/de1soc_cyclone5/de1_soc_defconfig*
