# Fernzugriff – SSH, VNC, Connect, Dateifreigaben, Netzwerk-Boot

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Remote access»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/remote-access.html)).

`setup-provisioning.md` beschreibt, wie ein Pi **beim ersten Start** erreichbar wird. Diese
Referenz beschreibt den **laufenden Betrieb**: Wie man das Gerät findet, wie man sicher
darauf zugreift, wie Daten hin- und herkommen – und wie ein Pi ganz ohne eigenes Boot-Medium
über das Netzwerk startet.

## Inhaltsverzeichnis
1. [Die drei Zugangswege](#die-drei-zugangswege)
2. [Das Gerät im Netz finden](#das-gerät-im-netz-finden)
3. [mDNS und der Klassensatz-Konflikt](#mdns-und-der-klassensatz-konflikt)
4. [SSH](#ssh)
5. [SSH ohne Passwort – Schlüssel](#ssh-ohne-passwort--schlüssel)
6. [VNC](#vnc)
7. [Raspberry Pi Connect](#raspberry-pi-connect)
8. [Dateien übertragen – welcher Weg](#dateien-übertragen--welcher-weg)
9. [scp und rsync](#scp-und-rsync)
10. [NFS](#nfs)
11. [Samba (SMB/CIFS)](#samba-smbcifs)
12. [Apache als Weboberfläche](#apache-als-weboberfläche)
13. [Netzwerk-Boot](#netzwerk-boot)
14. [Netzwerk-Boot über IPv6](#netzwerk-boot-über-ipv6)

---

## Die drei Zugangswege

| Weg | Was man bekommt | Braucht die IP-Adresse? | Über das Internet |
|-----|-----------------|-------------------------|-------------------|
| **SSH** | Terminal | Ja (oder mDNS-Name) | Nur über VPN oder Portfreigabe |
| **VNC** | Desktop-Bildschirmfreigabe | Ja | Nur über VPN oder Portfreigabe |
| **Raspberry Pi Connect** | Bildschirm **und** Terminal im Browser | **Nein** | ✅ Ohne Firewall-Änderung |

➜ **Für Edge-AI- und Sensorprojekte ist SSH der Normalfall**: Der Aufbau läuft headless,
und alles Nötige geschieht auf der Kommandozeile. VNC lohnt sich nur dort, wo eine
grafische Anwendung tatsächlich gebraucht wird – es kostet Bandbreite und setzt ein
Desktop-Image voraus.

> ⚠️ **SSH oder VNC direkt ins offene Internet zu stellen ist die schlechteste der
> Möglichkeiten.** Wo Fernzugriff von aussen nötig ist: **VPN** oder **Raspberry Pi
> Connect**. Wenn doch ein Port offen sein muss, gelten die Härtungsschritte aus
> `configuration.md` (Schlüssel statt Passwort, `ufw limit ssh/tcp`, fail2ban) als
> Minimum, nicht als Kür.

**Raspberry Pi Connect im Detail:**

| Funktion | Verfügbarkeit |
|----------|---------------|
| Remote Shell (Terminal) | **Alle** Pi-Modelle |
| Bildschirmfreigabe | Nur Modelle mit **Wayland**-Fenstersystem |

---

## Das Gerät im Netz finden

```bash
hostname -I                    # auf dem Pi selbst: die lokale IP-Adresse
nmcli device show              # ausführlich, je Schnittstelle
```

Bei `nmcli device show` den Block anhand von `GENERAL.TYPE` auswählen:

| `GENERAL.TYPE` | Bedeutung |
|----------------|-----------|
| `wifi` | Eingebautes WLAN |
| `ethernet` | Ethernet-Buchse |
| `loopback` | `lo`, immer 127.0.0.1 |
| `wifi-p2p` | `p2p-dev-wlan0` – **nicht** die gesuchte Schnittstelle |

Die Adresse steht in `IP4.ADDRESS[1]` (bzw. `IP6.ADDRESS[1]`); die angehängte Netzmaske
(`/24`) gehört nicht zur Adresse.

> ℹ️ **Wenn der Pi in die Konsole bootet**, steht die IP-Adresse in den letzten Zeilen vor
> der Anmeldeaufforderung. Mit Desktop zeigt der Mauszeiger über dem Netzwerksymbol
> Netzname und Adresse.

**Von aussen suchen, wenn kein Zugriff besteht:**

```bash
# Subnetz durchsuchen (Adressbereich an die eigene IP anpassen)
sudo nmap -sn 192.168.1.0/24

# Alle mDNS-Hosts und -Dienste im Netz auflisten
avahi-browse -a
```

Ergänzend: die Geräteliste im Router (nach **kabelgebundenen** Geräten filtern – die Liste
ist kürzer) oder eine Scanner-App wie Fing auf dem Telefon, die den Hersteller
«Raspberry Pi» direkt anzeigt.

> ⚠️ `nmap` kann je nach Netz eine Minute dauern. In verwalteten Netzen (Schule, Firma)
> gilt ein Portscan schnell als unerwünscht – vorher abklären.

---

## mDNS und der Klassensatz-Konflikt

Raspberry Pi OS meldet den eigenen Hostnamen über **Avahi** per Multicast-DNS:

```bash
ping raspberrypi.local
ssh benutzer@raspberrypi.local
```

Der Name folgt automatisch, wenn der Hostname über Control Centre, `raspi-config` oder
`/etc/hostname` geändert wird.

> 🔴 **Der Standard-Hostname ist auf jedem frischen System `raspberrypi`.** In einem
> Klassensatz oder Testaufbau melden damit **alle Geräte denselben Namen**. Welches
> `raspberrypi.local` antwortet, ist nicht vorhersagbar – und ein Befehl landet dann
> irgendwo. Der Fehler ist besonders tückisch, weil er bei einem einzelnen Gerät nie
> auftritt und beim zweiten sofort.

➜ **Konsequenz:** Hostnamen **vor** dem ersten Netzkontakt vergeben, systematisch
(`pi-01`, `pi-02`, …) und im Imager, nicht nachträglich. Das ist derselbe Punkt wie in
`setup-provisioning.md` – hier ist die Begründung.

➜ Zur eindeutigen **Identifikation** unabhängig vom Namen bleibt `rpi-machine-id` aus
`/proc/device-tree/chosen/` (siehe `configuration.md`).

> ⚠️ **mDNS setzt voraus, dass das Netz Multicast weiterleitet.** Viele Gast- und
> Schul-WLANs unterbinden das (Client Isolation). Dort funktioniert `.local` nicht, und
> die IP-Adresse oder eine DHCP-Reservation am Router ist der einzige Weg.

---

## SSH

Der SSH-Server ist in Raspberry Pi OS **ab Werk deaktiviert**. Aktivieren über den Imager
(`setup-provisioning.md`), `raspi-config` → *Interface Options* → *SSH*, Control Centre →
*Interfaces*, oder eine leere Datei `ssh` in der Boot-Partition.

```bash
ssh <benutzer>@<ip-adresse>
ssh <benutzer>@pi-01.local
```

Beim ersten Verbinden erscheint eine Sicherheitswarnung zum Hostschlüssel; mit `yes`
bestätigen. Sie erscheint danach nicht mehr.

> ⚠️ **Taucht die Warnung später erneut auf, ist das keine Formalität.** Entweder wurde das
> System neu aufgesetzt (dann neue Hostschlüssel), oder es antwortet ein anderes Gerät
> unter derselben Adresse – siehe den Klassensatz-Konflikt oben.

> ℹ️ **`connection timed out`** deutet fast immer auf die falsche IP-Adresse hin, nicht auf
> ein SSH-Problem.

**Grafische Programme über SSH (X11):**

```bash
ssh -Y <benutzer>@<ip-adresse>
geany &
```

Unter macOS und Windows ist dafür ein **X-Server eines Drittanbieters** nötig.

---

## SSH ohne Passwort – Schlüssel

Der empfohlene Weg für alles, was regelmässig oder automatisiert zugreift.

```bash
# Vorhandene Schlüssel prüfen
ls ~/.ssh          # id_ed25519.pub, id_rsa.pub oder id_dsa.pub → schon vorhanden

# Neuen Schlüssel erzeugen – Ed25519 ist die sicherere Wahl
ssh-keygen -t ed25519

# Agent starten und Schlüssel laden
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Öffentlichen Schlüssel auf den Pi bringen
ssh-copy-id <benutzer>@<ip-adresse>
```

> ℹ️ Die offizielle Anleitung zeigt `ssh-keygen` ohne Argumente (RSA) und nennt Ed25519 als
> Zusatzoption «für zusätzliche Sicherheit». **Für neue Aufbauten Ed25519 nehmen** –
> kürzere Schlüssel, moderneres Verfahren, in jedem aktuellen OpenSSH vorhanden.

Der private Schlüssel (`id_ed25519`) bleibt auf dem eigenen Rechner. Nur der öffentliche
(`id_ed25519.pub`) geht auf den Pi.

### 🔴 Der manuelle Weg zerstört vorhandene Schlüssel

Ohne `ssh-copy-id`:

```bash
# Auf dem Pi
mkdir .ssh
chmod 700 .ssh

# Auf dem eigenen Rechner
scp .ssh/id_ed25519.pub <benutzer>@<ip-adresse>:.ssh/authorized_keys

# Auf dem Pi
chmod 644 .ssh/authorized_keys
```

> 🔴 **Dieses `scp` überschreibt `authorized_keys` vollständig.** Es gilt nur, wenn noch
> **nie** ein Schlüssel hinterlegt wurde. Sind bereits welche eingetragen – etwa der
> Schlüssel einer Kollegin oder der eines Deployment-Systems –, muss der neue Schlüssel
> stattdessen **angehängt** werden:
>
> ```bash
> ssh-copy-id <benutzer>@<ip-adresse>          # macht genau das, korrekt
> # oder von Hand:
> cat ~/.ssh/id_ed25519.pub | ssh <benutzer>@<ip> 'cat >> ~/.ssh/authorized_keys'
> ```
>
> Der Unterschied ist ein einzelnes `>` gegen `>>` – und im Fehlerfall sperrt man alle
> anderen aus.

Die Berechtigungen sind nicht optional: `700` für `.ssh`, `644` für `authorized_keys`. Zu
weite Rechte lässt der SSH-Server stillschweigend ins Leere laufen.

---

## VNC

Raspberry Pi OS bringt **`wayvnc`** als VNC-Server mit; die Konfiguration liegt unter
`/etc/wayvnc/`.

```bash
sudo raspi-config     # Interface Options → VNC → Yes
```

Alternativ Control Centre → *Interfaces* → VNC.

**Client:** Empfohlen wird **TigerVNC** (Windows: `.exe`, macOS: `.dmg`, Linux: `.jar` mit
`sudo apt install default-jre` und `java -jar VncViewer-<version>.jar`).

> ⚠️ **Anleitungen, die RealVNC Viewer voraussetzen, sind überholt.** Der mitgelieferte
> Server ist heute `wayvnc`; TigerVNC ist der dokumentierte Gegenpart.

Beim Verbinden erscheinen zwei Zertifikatswarnungen («Hostname does not match the server
certificate», «signed by an unknown authority») – bei einem selbst aufgesetzten Gerät im
eigenen Netz erwartbar und mit *Yes* zu bestätigen.

> ℹ️ **Praktische Einstellung:** *Options → Input → «Show dot when no cursor»*. Ohne sie
> verschwindet der Mauszeiger in manchen Situationen ganz.

Voraussetzungen: gleiches Netz (oder VPN), Hostname oder IP-Adresse, gültige Zugangsdaten.
**VNC gibt es nicht mit den Lite-Varianten** (siehe `setup-provisioning.md`).

---

## Raspberry Pi Connect

Kostenloser Dienst von Raspberry Pi: Bildschirmfreigabe und Terminal **im Browser**, ohne
lokale IP-Adresse, ohne öffentliche IP, ohne Änderung an der Firewall.

➜ **Für Geräte hinter fremden Netzen ist das oft der einzige praktikable Weg** – im
Schulnetz, beim Kunden, hinter einem Mobilfunk-Router mit CGNAT. Es ersetzt kein VPN für
den Datenverkehr, löst aber das Zugriffsproblem ohne Portfreigabe.

Details zur Einrichtung in der Connect-Dokumentation; die Vorkonfiguration im Imager
beschreibt `setup-provisioning.md` (Achtung: persönliche Auth-Keys laufen nach **6 Stunden**
ab).

---

## Dateien übertragen – welcher Weg

| Werkzeug | Am besten für | Nicht geeignet für |
|----------|---------------|--------------------|
| **`scp`** | Einzelne Dateien, einmalig | Wiederholte Übertragung grosser Bestände |
| **`rsync`** | **Wiederholtes Abgleichen**, z.B. Messdaten oder Aufnahmen abholen | Gleichzeitiger Zugriff mehrerer Geräte |
| **NFS** | Dauerhaft eingebundene Verzeichnisse in einer **Linux/Unix**-Umgebung | Gastzugriffe, gemischte Betriebssysteme |
| **Samba** | **Gemischte Netze** (Windows, macOS, Linux), Gastzugriff | Feste Systemverzeichnisse wie `/home` |

➜ **Für den typischen Fall in diesem Skill – ein Feldgerät nimmt Bilder oder Messwerte auf,
die regelmässig abgeholt werden – ist `rsync` die richtige Wahl.** Es überträgt beim zweiten
Lauf nur Neues und verfolgt Änderungen und Löschungen.

---

## scp und rsync

```bash
# Zum Pi
scp datei.txt <benutzer>@<ip>:                 # ins Home-Verzeichnis
scp datei.txt <benutzer>@<ip>:projekt/          # in ein Unterverzeichnis
scp -r projekt/ <benutzer>@<ip>:                # ganzes Verzeichnis

# Vom Pi
scp <benutzer>@<ip>:datei.txt .

# Mehrere Dateien, Muster
scp *.txt <benutzer>@<ip>:
scp "datei mit leerzeichen.txt" <benutzer>@<ip>:
```

> ⚠️ **`scp` legt keine Verzeichnisse an.** Ein Zielverzeichnis muss vorher existieren,
> sonst schlägt die Übertragung fehl.

```bash
# Abgleich: Pi → eigener Rechner
mkdir aufnahmen
rsync -avz -e ssh <benutzer>@<ip>:aufnahmen/ aufnahmen/
```

| Schalter | Bedeutung |
|----------|-----------|
| `-a` | Archivmodus: Rechte, Zeitstempel, rekursiv |
| `-v` | Ausführliche Ausgabe |
| `-z` | Komprimierung während der Übertragung |
| `-e ssh` | Transport über SSH |

> ℹ️ **Der abschliessende `/` am Quellpfad ist bedeutungstragend.** `aufnahmen/` überträgt
> den **Inhalt** des Verzeichnisses, `aufnahmen` das Verzeichnis **selbst** in das Ziel
> hinein. Eine der häufigsten Verwechslungen bei `rsync`.

Beim wiederholten Aufruf überspringt `rsync` bereits übertragene Dateien und gleicht
gelöschte oder geänderte ab. In Kombination mit Schlüssel-Anmeldung und einem
`systemd`-Timer ergibt das eine automatische Datenabholung ohne weitere Software.

---

## NFS

Für dauerhaft eingebundene Verzeichnisse in einer Linux/Unix-Umgebung – der schlanke Weg zu
einem NAS. Voraussetzung: Vertrautheit mit Datei- und Verzeichnisrechten sowie mit
Ein- und Aushängen.

**Server:**

```bash
sudo apt install nfs-kernel-server

# Exporte an einer Stelle bündeln, echte Verzeichnisse hineinbinden
sudo mkdir -p /export/users
sudo mount --bind /home/users /export/users
```

`/etc/fstab` (damit die Bindung den Neustart überlebt):

```
/home/users    /export/users   none    bind  0  0
```

`/etc/exports`:

```
/export       192.168.1.0/24(rw,fsid=0,insecure,no_subtree_check,async)
/export/users 192.168.1.0/24(rw,nohide,insecure,no_subtree_check,async)
```

```bash
sudo exportfs -ra                          # nach JEDER Änderung an /etc/exports
sudo systemctl restart nfs-kernel-server
```

**Client:**

```bash
sudo apt install nfs-common
mount -t nfs -o proto=tcp,port=2049 <server-ip>:/ /mnt
mount -t nfs -o proto=tcp,port=2049 <server-ip>:/users /home/users
```

> ℹ️ Unter **NFSv4** genügt `:/` – der Wurzelexport zeigt auf das Verzeichnis mit `fsid=0`.
> Der aus NFSv3 bekannte Pfad `:/export` ist nicht mehr nötig.

### 🔴 Zwei Stolpersteine, die keine Fehlermeldung erzeugen

**1. Rechte hängen an der numerischen Benutzerkennung (UID).** Die UIDs auf dem Client
müssen zu denen auf dem Server passen, sonst greift der Zugriff auf fremde oder auf keine
Dateien. Abgleich über manuell gepflegte Passwortdateien, LDAP, NIS oder DNS. Für die
automatische Namenszuordnung muss `/etc/idmapd.conf` auf **beiden** Seiten identisch sein:

```ini
[Mapping]
Nobody-User = nobody
Nobody-Group = nogroup
```

> ⚠️ Andere Distributionen verwenden andere Namen (auf RedHat-Varianten `nfsnobody`). Mit
> `cat /etc/passwd` und `cat /etc/group` prüfen, statt zu raten.

**2. Es werden maximal 16 Gruppen vom Client zum Server übertragen.** Ist ein Benutzer auf
dem Client Mitglied in **mehr als 16 Gruppen**, sind einzelne Dateien oder Verzeichnisse
unerwartet unzugänglich – und zwar scheinbar willkürlich. Auf einem Pi mit den üblichen
Zusatzgruppen (`gpio`, `i2c`, `spi`, `video`, `dialout`, `plugdev`, …) ist diese Grenze
erreichbar.

### `sync` gegen `async`

| Option | Verhalten |
|--------|-----------|
| `sync` | Der Server antwortet erst, wenn Änderungen auf dem Datenträger sind – **die sichere Wahl** |
| `async` | Schneller, aber laut Dokumentation **gefährlich** – bei Stromausfall gehen bestätigte Schreibvorgänge verloren |

➜ Für ein Feldgerät oder einen Aufbau ohne USV ist `sync` die richtige Voreinstellung. Vor
dem Abweichen `man exports` lesen.

### Zugriff einschränken

Ohne weitere Massnahmen stehen die Dateien jedem im Netz offen. `/etc/hosts.deny`:

```
rpcbind mountd nfsd statd lockd rquotad : ALL
```

`/etc/hosts.allow` – nur die eigenen Adressen:

```
rpcbind mountd nfsd statd lockd rquotad : <Liste von IPv4-Adressen>
```

> ⚠️ **`127.0.0.1` in die erlaubte Liste aufnehmen.** Die Startskripte ermitteln die
> NFSv3-Unterstützung über `rpcinfo` – ohne Zugriff auf localhost wird sie abgeschaltet.
> Hostnamen funktionieren hier nicht; `rpcbind` verlangt Adressen.

> 🔴 **Grundsätzliche Grenze:** Ein Angreifer kann sich als berechtigte Maschine ausgeben
> und dann beliebige UIDs erzeugen. NFS allein authentifiziert das nicht. Wo das zählt,
> braucht es IPSec oder ein physisch getrenntes Netz.

**Bekanntes Problem:** Eine NFS-Freigabe in ein **verschlüsseltes Home-Verzeichnis** zu
mounten funktioniert über `/etc/fstab` nicht – beim Einhängen ist das Home noch nicht
entschlüsselt. Ausweg: an eine neutrale Stelle mounten (`/nfs/…`) und einen symbolischen
Link ins Home setzen.

---

## Samba (SMB/CIFS)

Der Weg für gemischte Netze. In Raspberry Pi OS **nicht vorinstalliert**:

```bash
sudo apt update
sudo apt install samba samba-common-bin smbclient cifs-utils
```

**Freigabe vom Pi anbieten:**

```bash
cd ~ && mkdir shared && chmod 0740 shared
sudo smbpasswd -a <benutzer>          # Samba-Passwort setzen – NICHT das Systempasswort
sudo nano /etc/samba/smb.conf
```

```ini
[share]
    path = /home/<benutzer>/shared
    read only = no
    public = yes
    writable = yes
```

Zusätzlich in derselben Datei `workgroup` auf die Arbeitsgruppe des lokalen Netzes setzen.

> ⚠️ **`smbpasswd` pflegt eine eigene Passwortdatenbank.** Ein geändertes Systempasswort
> ändert das Samba-Passwort nicht – und umgekehrt. Das erklärt «das Passwort stimmt doch».

**Windows-Freigabe auf dem Pi einbinden:**

```bash
mkdir windowshare
sudo mount.cifs //<host-oder-ip>/<freigabe> /home/<benutzer>/windowshare -o user=<name>
```

### 🔴 «Host is down» heisst nicht, dass der Host aus ist

> **Diese Fehlermeldung ist irreführend.** Sie bedeutet in aller Regel, dass sich Client und
> Server nicht auf eine **SMB-Protokollversion** einigen. Raspberry Pi OS nutzt
> voreingestellt 2.1 und neuer (Windows 7 aufwärts). Ältere Geräte – darunter viele
> NAS-Boxen und Netzwerkdrucker – brauchen 1.0.

```bash
sudo mount.cifs //<ip>/<freigabe> /mnt/punkt -o user=<name>,vers=1.0
```

| Wert | Protokoll |
|------|-----------|
| `1.0` | Klassisches CIFS/SMBv1 |
| `2.0` | Windows Vista SP1, Server 2008 |
| `2.1` | Windows 7, Server 2008 R2 |
| `3.0` | Windows 8, Server 2012 |
| `3.02` | Windows 8.1, Server 2012 R2 |
| `3.11` | Windows 10, Server 2016 |
| `3` | SMBv3.0 und neuer |

➜ Der Reihe nach durchprobieren, **beginnend beim höchsten** Wert, den die Gegenstelle
können sollte. SMBv1 gilt als unsicher und ist nur die letzte Wahl für Altgeräte.

---

## Apache als Weboberfläche

Für ein Statusdashboard oder eine kleine Bedienoberfläche auf dem Gerät:

```bash
sudo apt update
sudo apt install apache2 -y
```

Prüfen über `http://localhost/` auf dem Pi oder `http://<ip-adresse>` von aussen.

Die Startseite liegt unter `/var/www/html/index.html` und gehört **`root`**:

```bash
sudo chown <benutzer>: /var/www/html/index.html
```

PHP nachrüsten:

```bash
sudo apt install php libapache2-mod-php -y
```

> ⚠️ **Ein Webserver auf einem Feldgerät ist eine offene Tür.** Zusammen mit der Firewall
> aus `configuration.md` einrichten (`ufw allow 80/tcp` nur dort, wo nötig) und `phpinfo()`
> nach dem Test wieder entfernen – die Ausgabe verrät die vollständige Systemkonfiguration.

---

## Netzwerk-Boot

Ein Pi 3 oder neuer startet ohne eigenes Boot-Medium von einem DHCP/TFTP-Server. Für
Klassensätze und Prüfstände interessant: Ein zentral gepflegtes Abbild, keine SD-Karten,
die verloren gehen oder verschleissen.

> ⚠️ **Keine Erfolgsgarantie.** Raspberry Pi weist ausdrücklich darauf hin, dass die Vielfalt
> an Routern und Switches keine allgemeine Zusage erlaubt. Bei Problemen hilft es
> berichteterweise, **STP-Frames** im Netz abzuschalten.

### Client vorbereiten

| Modell | Vorgehen |
|--------|----------|
| **Pi 3B** | Einmalig `program_usb_boot_mode=1` in `config.txt`, neu starten, Zeile wieder entfernen |
| **Pi 3B+** | Ab Werk aktiviert |
| **Pi 4 und neuer** | `raspi-config` → *Advanced Options* → *Boot Order* → *Network Boot* |

```bash
# Pi 3B: setzen, neu starten, prüfen
echo program_usb_boot_mode=1 | sudo tee -a /boot/firmware/config.txt
sudo reboot
vcgencmd otp_dump | grep 17:        # erwartet: 17:3020000a

# Pi 4 und neuer: Bootreihenfolge prüfen
vcgencmd bootloader_config          # erwartet: BOOT_ORDER=0xf21
```

> 🔴 **`program_usb_boot_mode` schreibt in den OTP-Speicher – das ist unumkehrbar.** Die
> Zeile danach wieder aus `config.txt` entfernen; das gesetzte Bit bleibt. Auf dem Pi 4 und
> neuer wird stattdessen die Bootreihenfolge im EEPROM verändert, was rückgängig zu machen
> ist.

### 🔴 Ab Pi 4 hat die MAC-Adresse nichts mehr mit der Seriennummer zu tun

```bash
ethtool -P eth0                                        # MAC-Adresse
grep Serial /proc/cpuinfo | cut -d ' ' -f 2 | cut -c 9-16   # Seriennummer
```

> **Auf Pi 4 und neueren Flaggschiff-Modellen wird die MAC-Adresse bei der Fertigung
> programmiert; es gibt keinen Zusammenhang mehr zur Seriennummer.** Wer DHCP-Reservationen
> oder TFTP-Zuordnungen aus der Seriennummer ableitet – ein auf älteren Modellen gängiges
> Verfahren –, bekommt auf neuer Hardware falsche Werte.

➜ **Beide Angaben pro Gerät auslesen und dokumentieren**, bevor der Aufbau ins Netz geht.
Beide erscheinen auch auf dem HDMI-Diagnosebildschirm des Bootloaders.

### Server einrichten – der Ablauf

1. **Wurzeldateisystem für den Client anlegen** (Kopie des Servers):
   ```bash
   sudo mkdir -p /nfs/client1
   sudo apt install rsync
   sudo rsync -xa --progress --exclude /nfs / /nfs/client1
   ```
2. **SSH-Hostschlüssel im Client-Dateisystem neu erzeugen** – per `chroot`, sonst teilen
   sich alle Clients die Schlüssel des Servers:
   ```bash
   cd /nfs/client1
   sudo mount --bind /dev dev && sudo mount --bind /sys sys && sudo mount --bind /proc proc
   sudo chroot .
   rm /etc/ssh/ssh_host_*
   dpkg-reconfigure openssh-server
   exit
   sudo umount dev sys proc
   ```
3. **Feste Adresse für den Server** über `systemd-networkd`
   (`/etc/systemd/network/10-eth0.netdev` und `11-eth0.network`), DNS in
   `/etc/systemd/resolved.conf`.
4. **`dnsmasq` als Proxy-DHCP und TFTP-Server:**
   ```
   port=0
   dhcp-range=10.42.0.255,proxy
   log-dhcp
   enable-tftp
   tftp-root=/tftpboot
   pxe-service=0,"Raspberry Pi Boot"
   ```
5. **Boot-Dateien bereitstellen:** `cp -r /boot/firmware/* /tftpboot`
6. **NFS-Wurzel exportieren:**
   ```
   /nfs/client1 *(rw,sync,no_subtree_check,no_root_squash)
   /tftpboot    *(rw,sync,no_subtree_check,no_root_squash)
   ```
7. **`/tftpboot/cmdline.txt`** ab `root=` ersetzen (und ein etwaiges `init=` entfernen):
   ```
   root=/dev/nfs nfsroot=10.42.0.211:/nfs/client1,vers=3 rw ip=dhcp rootwait
   ```
8. **`/nfs/client1/etc/fstab`:** die `mmcblk0p1`/`p2`-Zeilen entfernen, Boot-Partition per
   NFS eintragen.

**Diagnose:**

```bash
sudo tcpdump -i eth0 port bootpc    # kommt überhaupt eine DHCP-Anfrage vom Client?
journalctl -f                       # dnsmasq: welche Datei wird gesucht und fehlt?
```

> ℹ️ Die erste sichtbare Meldung ist typischerweise
> `file /tftpboot/bootcode.bin not found` – das ist **Fortschritt**, nicht das Ende: Der
> Client hat den Server gefunden und fragt nach Dateien, die noch nicht kopiert sind.

> 🔴 **`no_root_squash` in diesen Exporten bedeutet, dass `root` des Clients auch auf dem
> Server `root` ist.** Für Netzwerk-Boot ist das nötig, für alle anderen Freigaben ein
> ernsthaftes Risiko. Nicht aus dieser Anleitung in eine gewöhnliche Dateifreigabe
> übernehmen.

Beim ersten Versuch Geduld: Der Startvorgang kann eine Minute dauern.

---

## Netzwerk-Boot über IPv6

> 🔴 **Experimentell (Alpha), nur Pi 4 und CM4.** Raspberry Pi behält sich ausdrücklich vor,
> das Verfahren zu ändern.

Der Ablauf in vier Schritten: Bootloader holt per DHCPv6 Adresse und TFTP-Server →
Bootloader lädt die Firmware (`start4.elf`) → Firmware lädt Kernel und Kommandozeile →
Kernel bindet das Wurzeldateisystem ein.

**Die Schritte 1 bis 3 sind umgesetzt, Schritt 4 nicht.**

> 🔴 **`nfsroot` unterstützt kein IPv6.** Ein Mechanismus, den Linux-Kernel mit NFS über
> IPv6 zu starten, ist laut Dokumentation **noch nicht demonstriert**. Denkbar wäre eine
> kleine RAM-Disk, die die Netzwerkquelle einbindet und dann umschaltet.

➜ **Konsequenz: IPv6-Netzwerk-Boot ist derzeit nicht durchgängig einsetzbar.** Wer heute
netzwerkbootet, tut das über IPv4.

Zwei weitere Einschränkungen:

- **`dnsmasq` unterstützt die nötigen DHCPv6-Parameter nicht** – es braucht einen anderen
  Server, etwa `isc-dhcp-server`. Der TFTP-Teil von `dnsmasq` kann dagegen weiterverwendet
  werden, er spricht beide Protokolle.
- Ohne IPv6 bei Router und Provider bleibt der Nutzen begrenzt.

```bash
# Unterstützt das eigene Netz IPv6? Und staatsbehaftet oder zustandslos?
sudo apt install ndisc6
rdisc6 -1 eth0        # «Stateful address conf.: Yes» → Adressvergabe per DHCPv6
```

**Bootloader-Konfiguration:**

```
BOOT_ORDER=0xf21      # 2 = Netzwerk-Boot
USE_IPV6=1            # IPv6 aktivieren – zum Zurückschalten die Zeile entfernen
BOOT_UART=1           # Diagnoseausgabe
```

Mit `BOOT_UART=1` zeigen Zeilen mit dem Präfix `RX6:` an, dass tatsächlich IPv6 verwendet
wird. Detaillierte Analyse mit `sudo tcpdump -i eth0 -e ip6 -XX -l -v -vv`.

---

## Weitere Ressourcen

- [Remote access](https://www.raspberrypi.com/documentation/computers/remote-access.html)
- [Raspberry Pi Connect](https://www.raspberrypi.com/documentation/services/connect.html)
- [Raspberry Pi Bootloader Configuration](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#bootloader-configuration)
- `setup-provisioning.md` – erster Start, Imager, Headless-Vorkonfiguration
- `configuration.md` – SSH härten, UFW, fail2ban, `fstab`
- `config-txt.md` – `BOOT_ORDER`, bedingte Filter, EEPROM-Einstellungen
