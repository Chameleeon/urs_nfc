# NFC 2 Click sa DE1-SoC pločom

Konfiguracija DE1-SoC ploče koja omogućava upotrebu NFC 2 Click ploče na Linux operativnom sistemu. Kako bi ovo bilo moguće, potrebno je konfigurisati FPGA kako bi GPIO kontroler spojen na FPGA mogao da upravlja prekidima, koji su potrebni za ispravno funkcionisanje NFC 2 Click ploče.
FPGA konfiguracija omogućena je fajlovima *socfpga.rbf* koji se nalazi na putanji *buildroot/board/terasic/de1soc_cyclone5* i de1soc_handoff.patch koji se nalazi na putanji *buildroot/board/terasic/de1soc_cyclone5/patches/u-boot*.

## Toolchain

Crosstool-NG je korišten kao toolchain za kros-kompajliranje. Konfigurisan za ARM arhitekturu.
Kao početna konfiguracija korištena je konfiguracjia *arm-cortexa9_linux-gnueabihf*.

Nakon toga, potrebno je napraviti dodatne izmjene.
- U okviru *Paths and misc options*
  -  omogućiti opciju *Try feature marked as EXPERIMENTAL* i
  -  isključiti opciju *Render the toolchain read-only*
-  U okviru *Target options*:
  -  Postaviti *cortex-a9* za *Emit assembly for CPU* opciju
  -  unijeti *neon* za *Use specific FPU* opciju
- U okviru *Toolchain options*:
  - postaviti *Tuple's vendor string* na željenu vrijednost
  - postaviti *Tuple's alias* opciju na **arm-linux**
- U okviru *Operating System*:
  - odabrati 6.1.35 u *Version of linux* opciji
- U okviru *C-library*:
  - odabrati **glibc** u *C library* opciji
  - odabrati verziju 2.38 u *Version of glibc* opciji
  - uključiti opciju *Enable obsolete libcrypt*
- U okviru *C compiler*
  -  postaviti *Version of gcc* opciju na 13.2.0
  -  omogućiti podršku za C++

Nakon toga je potrebno generisati toolchain komandom ```ct-ng build```.
Kako bi se moago koristiti toolchain, potrebno je exportovati određene sistemske varijable, što je moguće uraditi komandom
```bash
source ./set-env.sh
```
unutar direktorijuma ovog repozitorijuma.

## Buildroot

Kao alat za automatizaciju procesa izgradnje svih potrebnih komponenti za pokretanje Linux jezgra na ploči i upotrebu NFC 2 Click ploče sa PN7150 modulom, korišten je Buildroot projekat. Svi fajlovi potrebni za konfiguraciju Buildroot projekta smješteni su unutar *buildroot* foldera u okviru ovog repozitorijuma.

Korištena verzija Buildroot-a je 2024.02.

Kao početna konfiguracija preporučuje se upotreba konfiguracije *buildroot/configs/de1soc_defconfig*. 
Da bi se ova konfiguracija upotrijebila potrebno je prvo klonirati Buildroot repozitorijum i prebaciti se na odgovarajuću verziju:
```bash
git clone https://gitlab.com/buildroot.org/buildroot.git
cd buildroot
git checkout 2024.02
```
Zatim je *de1soc_defconfig* fajl potrebno prekopirati u *configs* folder unutar kloniranog direktorijuma.
Konfiguraciju tada možemo selektovati komandom
```bash
make de1soc_defconfig
```
Takođe je potrebno prekopirati cijeli *board* folder u novi klonirani direktorijum.
```bash
cp -r /path/to/this/repo/board .
```
Nakon selektovanja ove konfiguracije potrebno je promijeniti putanju do Toolchain-a. Po potrebi se mogu promijeniti i ostali parametri. Prije neko što se pristupi generisanju kompresovane slike, potrebno je proći konfiguraciju ostalih parametara vezanih za U-Boot i Linux kernel, koji su navedeni u odgovarajućim sekcijama ispod.

Nakon čuvanja konfiguracije kompletna kompresovana slika se može generisati komandom ```make``` u buildroot folderu.

## U-Boot

Kao Bootloader koji učitava kernel i root filesystem korišten je **U-Boot**, verzija 2024.01.
Učitavanje slike jezgra i filesystem-a se vrši sa SD kartice na odgovarajuće memorijske adrese.
Proces učitavanja i pokretanja je automatizovan upotrebom fajla *buildroot/board/terasic/de1soc_cyclone5/boot-env.txt* koji podešava U-Boot okruženje za pravilno pokretanje.

Kao konfiguraciju za U-Boot koristi se predefinisana konfiguracija pod nazivom *socfpga_de1_soc_defconfig* pa je ovo potrebno definisati unutar konfiguracionog menija za *Buildroot* pod kategorijom *U-Boot* kao opciju *In-tree defconfig* (parametar ```BR2_TARGET_UBOOT_USE_DEFCONFIG```).
Potrebno je takođe podesiti putanju do patch fajla koji se nalazi na putanji *buildroot/board/terasic/de1soc_cyclone5/patches/u-boot*.

## Linux kernel

Verzija Linux jezgra koje je korišteno je *socfpga-6.1.38-lts* dostupna na [ovom](https://github.com/altera-opensource/linux-socfpga) linku.
Kao polazna konfiguracija korišten je *socfpga_defconfig*.
Izmjene koje je potrebno napraviti za ispravno funkcionisanje su:
* parametar `CONFIG_LOCALVERSION` postaviti na -etfbl-lab (ili željenu vrijednost) u **General setup**
* isključiti opciju **Automatically append version information to the version string**
* kod kategorije **Boot options** postaviti opciju **Default kernel command string** na *console* i zatim na **Kernel command line type** postaviti *Use bootloader kernel arguments if available*.

Takođe je potrebno u **Drivers** -> **Misc devices** NXP drajver ubaciti kao modul, što je detaljnije opisano u sljedećem dijelu teksta.

Ukoliko dođe do greške pri kompajliranju kernela gdje nedostaju određeni fajlsistemi, potrebno je u *buildroot/output/linux-6.1.35-socfpga/fs/filesystems-gperf.gperf* fajlu dodati sljedeća dva unosa na kraju:
```
bcachefs,       {BCACHEFS_SUPER_MAGIC}
pidfs,          {PID_FS_MAGIC}
```

## Drajver

Prije kompajliranja kernela potrebno je ubaciti drajver za PN7150 koji se nalazi u folderu *nxp-pn5xx*.
Uputstvo za ubacivanje drajvera je dostupno na [ovom](https://www.nxp.com/docs/en/application-note/AN11697.pdf) linku.
Drajver je ubačen kao modul u defconfig fajlu kernela koji se nalazi u folderu *buildroot/board/terasic/de1soc_cyclone5/de1_soc_defconfig*

Drajver je modifikovan tako da su popravljene određene kompajlerske greške i tako dostupan unutar ovog repozirorijuma u folderu **nxp-pn5xx**.
Modifikacije koje su napravljene su sljedeće:
- pozivi funkcija **pr_warning()** promijenjeni u **pr_warn()**
- tip funkcije **pn54x_remove()** promijenjen iz **int** u **void**
- uklonjena linija ```return 0;``` iz funkcije **pn54x_remove()**

Prije ovih izmjena, kompajliranje drajvera je dovdilo do kompajlerske greške.

## Device Tree

Za ispravno funkcionisanje PN7150 modula na DE1-SoC ploči potrebno je ispravno konfigurisati odgovarajući uređaj i prekide na FPGA GPIO kontroleru. Ovo je urađeno u fajlu *buildroot/board/de1soc_cyclone5/socfpga_cyclone5_de1_soc.dts*. Ovaj fajl je potrebno proslijediti kernelu kroz Make config, što je urađeno u defconfig fajlu za Buildroot.

U DTS fajlu su definisana dva nova čvora:

* gpio_altr - GPIO kontroler povezan na FPGA koji upravlja prekidima. Potrebno ga je definisati kako bi PN7150 mogao ispravno da funkcioniše. Ključno, potrebno je definisati ovaj GPIO kontroler kao interrupt kontroler, a kao tip interrupta potrebno je postaviti **4 (Level High).**
* pn7150 - podčvor i2c2 čvora koji opisuje sam PN7150 uređaj i definiše VEN i IRQ pinove na gore pomenutom kontroleru.

Za više detalja o konfiguraciji pogledati gore pomenuti *dts* fajl.

## Demo aplikacija

Za testiranje funkcionalnosti PN7150 modula korištena je Demo aplikacija dostupna u sklopu *[libnfc-nci](https://github.com/NXPNFCLinux/linux_libnfc-nci)* biblioteke. Detaljna uputstva za preuzimanje, instalaciju i upotrebu biblioteke dostupna su na [ovom](https://www.nxp.com/docs/en/application-note/AN11697.pdf) linku.

U slučaju ovog projekta, biblioteka i demo aplikacija su kroskompajlirane za ARM arhitekturu i ubačene u *rootfs* podfolder na odgovarajuće lokacije kako bi se omogućilo funkcionisanje kako demo aplikacije tako i bilo koje druge aplikacije koja koristi dijeljene NFC NCI biblioteke.
Pored ovoga, potrebno je konfguracione fajlove koji se nalaze u repozitorijumu biblioteke u folderu *conf* smjestiti unutar */usr/local/etc* foldera na ciljnoj platformi.

## Zaključak

Gore navedenom konfiguracijom omogućeno je pokretanje Linux jezgra na DE1-SoC platformi sa podrškom za prekide putem FPGA GPIO kontrolera. Nakon pokretanja Linux jezgra, upotrebom serijskog interfejsa moguća je komunikacija sa pločom sa razvojne platforme.

Unutar */root* direktorijuma na ciljnoj platformi nalazi se aplikacija **nfcDemoApp** koja služi za testiranje funkcionalnosti PN7150 modula. 
Prije pokretanja ove aplikacije potrebno je da bude učitan drajver *pn5xx_i2c.ko*. Trebalo bi da bude učitan automatski, što možemo provjeriti komandom ```lsmod | grep pn```. Ukoliko drajver nije učitan, potrebno ga je učitati komandom ```modprobe pn5xx_i2c```. 
Učitavanjem drajvera pojavljuje se device node **/dev/pn544** koji možemo koristiti za komunikaciju sa modulom.

Nakon toga, možemo pokrenuti aplikaciju. Za ispis ponuđenih opcija koristi se ```./nfcDemoApp -h```.
Najjednostavniji testni slučaj je *Polling* režim gdje aplikacija čeka da se primakne NFC tag, i nakon toga ispisuje detalje o detektovanom tagu. Za pokretanje aplikacije u *Polling* režimu, koristi se komanda:
```bash
./nfcDemoApp poll
```

Ukoliko se uključe logovi za aplikaciju modifikacijom fajla */usr/local/etc/libnfc-nxp-init.conf* podešavanjem određenih vrijednosti na sljedeći način:
```
NXPLOG_GLOBAL_LOGLEVEL=0x03
NXPLOG_EXTNS_LOGLEVEL=0x03
NXPLOG_NCIHAL_LOGLEVEL=0x03
NXPLOG_NCIX_LOGLEVEL=0x03
NXPLOG_NCIR_LOGLEVEL=0x03
NXPLOG_FWDNLD_LOGLEVEL=0x03
NXPLOG_TML_LOGLEVEL=0x03
```
kao i fajla *libnfc-nci.conf* u istom direktorijumu:
```
APPL_TRACE_LEVEL=0xFF
PROTOCOL_TRACE_LEVEL=0xFF
```

možemo dobiti detaljan ispis događaja tokom konfiguracije PN7150 modula za *Polling* režim, što nam daje informaciju o tome da je modul uspješno konfigurisan za **RF_DISCOVERY** odnosno da čeka da mu se prinese NFC tag.

Međutim, prinošenje NFC taga ne donosi nikakvu promjenu na IRQ pinu, što znači da se NFC tag nikada ne detektuje.
Razlog za ovo može biti potencijalni hardverski problem sa RF antenom (prekid u namotaju ili loš kontakt) ili problem sa drajverom.

Prvi pokušaj je bio sa prekidima na obje ivice. Za to je bilo potrebno modifikovati sljedeću liniju u drajveru:
```C
ret = request_irq(client->irq, pn54x_dev_irq_handler, IRQF_TRIGGER_HIGH, client->name, pn54x_dev);
```
tako da izgleda ovako:
```C
ret = request_irq(client->irq, pn54x_dev_irq_handler, IRQF_TRIGGER_RISING | IRQF_TRIGGER_FALLING, client->name, pn54x_dev);
```
Međutim, ovo je dovodilo do lažnih prekida.
Sljedeći pokušaj je bio sa prekidima tipa **LEVEL HIGH**, što je riješilo problem lažnih prekida koji su se javljali na opadajuću ivicu, ali nije riješilo problem detektovanja NFC taga.

Ono što je sigurno jeste da prekidi rade ispravno tokom inicijlizacije modula, jer *read* funkcija u drajveru zahtijeva da IRQ pin bude **HIGH** prije nego što pristupi čitanju. Ukoliko je IRQ pin na niskom logičkom nivou kada se zahtijeva čitanje, drajver čeka da se promijeni stanje IRQ pina prije nego što počne da čita podatke.
S obzirom na to da Demo aplikacija šalje konfiguracione NCI poruke modulu i čita njegove odgovore na njih, možemo zaključiti da kada PN7150 modul dobije konfiguracionu poruku, šalje odgovor na nju i podiže IRQ pin na **HIGH** logički nivo.

Za otkrivanje stvarnog problema potrebno je uraditi detaljniju analizu izvornog koda drajvera jer na prvi pogled nema značajnu grešku i čitanje očigledno radi ispravno, kao i detaljnije ispitivanje RF antene.
