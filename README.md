# NFC 2 Click sa DE1-SoC pločom

Konfiguracija DE1-SoC ploče koja omogućava upotrebu NFC 2 Click ploče na Linux operativnom sistemu.

## Buildroot

Kao alat za automatizaciju procesa izgradnje svih potrebnih komponenti za pokretanje Linux jezgra na ploči i upotrebu NFC 2 Click ploče sa PN7150 modulom, korišten je Buildroot projekat. Svi fajlovi potrebni za konfiguraciju Buildroot projekta smješteni su unutar *buildroot* foldera u okviru ovog repozitorijuma.

Korištena verzija Buildroot-a je 2024.02.

Kao početna konfiguracija preporučuje se upotreba konfiguracije *buildroot/configs/de1soc_defconfig*. Nakon selektovanja ove konfiguracije potrebno je promijeniti putanju do Toolchain-a.

## Linux kernel

Verzija Linux jezgra koje je korišteno je *socfpga-6.1.38-lts* dostupna na (ovom)[https://github.com/altera-opensource/linux-socfpga] linku.
Kao polazna konfiguracija korišten je *socfpga_defconfig*.
Izmjene koje je potrebno napraviti za ispravno funkcionisanje su:
* parametar `CONFIG_LOCALVERSION` postaviti na -etfbl-lab (ili željenu vrijednost) u **General setup**
* isključiti opciju **Automatically append version information to the version string**
* kod kategorije **Boot options** postaviti opciju **Default kernel command string** na *console* i zatim na **Kernel command line type** postaviti *Use bootloader kernel arguments if available*.

Takođe je potrebno u **Drivers** -> **Misc devices** NXP drajver ubaciti kao modul, što je detaljnije opisano u sljedećem dijelu teksta.

## Drajver

Prije kompajliranja kernela potrebno je ubaciti drajver za PN7150 koji se nalazi u folderu *nxp-pn5xx*. Drajver je modifikovan tako da su popravljene određene kompajlerske greške.
Uputstvo za ubacivanje drajvera je dostupno na [ovom](https://www.nxp.com/docs/en/application-note/AN11697.pdf) linku.
Drajver je ubačen kao modul u defconfig fajlu kernela koji se nalazi u folderu *buildroot/board/terasic/de1soc_cyclone5/de1_soc_defconfig*

## Device Tree

Za ispravno funkcionisanje PN7150 modula na DE1-SoC ploči potrebno je ispravno konfigurisati odgovarajući uređaj i prekide na FPGA GPIO kontroleru. Ovo je urađeno u fajlu *buildroot/board/de1soc_cyclone5/socfpga_cyclone5_de1_soc.dts*. Ovaj fajl je potrebno proslijediti kernelu kroz Make config, što je urađeno u defconfig fajlu za Buildroot.

U DTS fajlu su definisana dva nova čvora:

* gpio_altr - GPIO kontroler povezan na FPGA koji upravlja prekidima. Potrebno ga je definisati kako bi PN7150 mogao ispravno da funkcioniše.
* pn7150 - podčvor i2c2 čvora koji opisuje sam PN7150 uređaj i definiše VEN i IRQ pinove na gore pomenutom kontroleru.

