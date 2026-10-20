# TrimrPix for iOS 1.5.1: listing

Everything for 1.5.1's App Store Connect fields in one place, for the hub to fill in and the
owner to approve. Five locales: en-AU (primary), da, de-DE, fr-FR, ja. Each block between the
fences is pasted as it stands. No em-dashes anywhere, and no claim the app can't back: every
feature line was checked against the code on `main`.

The starting point is the live 1.5.0 text as the hub recorded it on 2026-10-12
(`TrimrPix-iOS/app-store-copy.md` in the hub). Only the fields below change.

Counted, in characters:

| Field (limit) | en-AU | da | de-DE | fr-FR | ja |
|---|---|---|---|---|---|
| Description (4,000) | 1,372 | 1,422 | 1,508 | 1,552 | 687 |
| Keywords (100) | 98 | 95 | 97 | 92 | 69 |
| What's New (4,000) | 458 | 495 | 547 | 586 | 226 |

## What 1.5.1 carries

- **WebP photos are skipped instead of failing** (#71, #73). iOS can read WebP but has no WebP
  encoder, so every WebP photo used to fail. They are now left as they are and listed as
  Skipped on the result screen, with the reason.
- **Target size really leaves smaller photos alone** (#73, #74). Photos already at or under
  the target are skipped: no re-encode, no edit in Photos. The size is measured on the photo as
  the library holds it now, not on the picker's copy, which can be a different size.
- **Savings are counted from the photo in the library** (#76). Space saved, Avg. savings and the
  running total used the picker's copy, which can be smaller or larger than the library's file.
  The estimate before compressing still uses the picker's copy: reading the library needs Photos
  access, which the app only asks for when you compress.
- **A photo is never replaced with a bigger one** (#77). The output is compared with the photo in
  the library, and a photo that wouldn't get smaller is left as it is and listed as Skipped.
- **New screenshots** for iPhone and iPad, in place of the April set that still shows the format
  picker removed in 1.1. See [Screenshots](#screenshots).

---

## Name and subtitle (unchanged)

Listed so the keyword check below can be read against them. Nothing to paste.

| Locale | Name | Subtitle |
|---|---|---|
| en-AU | `TrimrPix: Photo Compressor` | `Shrink in place, no duplicates` |
| da | `TrimrPix: Komprimer billeder` | `Uden dubletter, frigør plads` |
| de-DE | `TrimrPix: Fotos komprimieren` | `Ohne Duplikate, spart Platz` |
| fr-FR | `TrimrPix: Compresser photos` | `Sans doublons, libère l'espace` |
| ja | `TrimrPix: 写真を圧縮・容量節約` | `重複なし。元のファイルをその場で置き換え` |

---

## Promotional text (unchanged)

Re-paste only if App Store Connect shows it empty on the new version.

**en-AU**
```
Pick your photos, choose a quality level or an exact size, and slide to confirm. It all happens on your iPhone. No cloud, no accounts, no ads, pay once.
```
**da**
```
Vælg dine billeder, vælg et kvalitetsniveau eller en præcis størrelse, og skub for at bekræfte. Alt sker på din iPhone. Ingen sky, ingen konti, ingen reklamer.
```
**de-DE**
```
Fotos auswählen, Qualitätsstufe oder genaue Größe festlegen, zum Bestätigen wischen. Alles passiert auf deinem iPhone. Keine Cloud, keine Konten, keine Werbung.
```
**fr-FR**
```
Choisissez vos photos, un niveau de qualité ou une taille précise, puis glissez pour confirmer. Tout se passe sur votre iPhone. Sans cloud, sans compte, sans pub.
```
**ja**
```
写真を選び、画質か正確なサイズを指定して、スライドで確定。すべてiPhone上で完結します。クラウドなし、アカウントなし、広告なし、買い切り。
```

---

## Keywords

`WebP` is out of all five. The freed characters go to terms the app backs, none of them already
in that locale's name or subtitle:

- **upload** (en-AU, da, de-DE): Target size exists to fit a photo under an upload or attachment
  limit, which is how the 1.3 release notes put it.
- **poids** (fr-FR): the everyday French word for a file's size ("réduire le poids d'une photo").
- **GPS** (fr-FR): the app can strip GPS from the compressed photo; en-AU and da already carry it.
- **画質** (ja): image quality, the app's own label for the quality levels. Japanese is a first
  pass, so this is the only addition there.

| Locale | Value | Chars |
|---|---|---|
| en-AU | `reduce,file,size,smaller,resize,batch,quality,JPEG,PNG,HEIC,EXIF,metadata,GPS,offline,space,upload` | 98 |
| da | `reducer,filstørrelse,mindre,fotos,batch,kvalitet,JPEG,PNG,HEIC,EXIF,metadata,GPS,offline,upload` | 95 |
| de-DE | `verkleinern,dateigröße,bilder,kleiner,stapel,qualität,JPEG,PNG,HEIC,EXIF,metadaten,offline,upload` | 97 |
| fr-FR | `réduire,taille,fichier,image,lot,qualité,JPEG,PNG,HEIC,EXIF,métadonnées,hors ligne,poids,GPS` | 92 |
| ja | `画像 縮小,目標サイズ,軽量化,一括処理,JPEG,PNG,HEIC,EXIF 削除,メタデータ,位置情報,オフライン,アップロード,画質` | 69 |

**en-AU**
```
reduce,file,size,smaller,resize,batch,quality,JPEG,PNG,HEIC,EXIF,metadata,GPS,offline,space,upload
```
**da**
```
reducer,filstørrelse,mindre,fotos,batch,kvalitet,JPEG,PNG,HEIC,EXIF,metadata,GPS,offline,upload
```
**de-DE**
```
verkleinern,dateigröße,bilder,kleiner,stapel,qualität,JPEG,PNG,HEIC,EXIF,metadaten,offline,upload
```
**fr-FR**
```
réduire,taille,fichier,image,lot,qualité,JPEG,PNG,HEIC,EXIF,métadonnées,hors ligne,poids,GPS
```
**ja**
```
画像 縮小,目標サイズ,軽量化,一括処理,JPEG,PNG,HEIC,EXIF 削除,メタデータ,位置情報,オフライン,アップロード,画質
```

---

## Description

Four changes from the live text, in all five locales:

- **Formats:** "JPEG, PNG, WebP, and HEIC" becomes "JPEG, PNG, and HEIC". A WebP photo is left
  as it is; the app doesn't claim it anywhere now.
- **The second paragraph** loses "Most photo compressors save a smaller copy and leave the
  original behind…". It is a claim about other apps resting on the hub's five-app survey from
  April, the same reason the site dropped "Other compressors can't do this." (`a21c90c`). The
  first paragraph already says there is no duplicate album, so the paragraph keeps only the
  three steps.
- **Metadata control** says what the setting does: it chooses what the compressed photo keeps.
  "Strip GPS location" and "You decide what stays and what goes" are gone. Photos keeps its own
  record of where a photo was taken, and the delete-and-recreate path copies that location onto
  the new photo on purpose, so turning GPS off doesn't remove the location from the library. A
  new line says so.
- **The closing paragraph** loses "cannot be undone". Photos keeps the original of an in-place
  edit and offers Revert to Original, and the delete-and-recreate path leaves the original in
  Recently Deleted for 30 days (Apple documents both). It now says only that compressing
  replaces the photo in your library, which is why the app asks you to confirm. The app's own
  confirm screen still says "This cannot be undone" until the next build; that over-warns
  rather than under-warns.

Everything else is the live text, word for word.

### en-AU
```
I built TrimrPix to do one thing well. It makes the photos in your iPhone library smaller, and it replaces the originals in place. There is no duplicate album to clean up afterwards, nothing is uploaded, and it needs no internet connection.

Pick your photos, choose your settings, slide to confirm.

One-time purchase. $1.99, no subscription, no ads, no tracking.

TWO WAYS TO COMPRESS
• Quality: Same, Good, or Smaller
• Target size: set a per-photo limit (500 KB, 1 MB, 2 MB, 5 MB, or a size you type in) and TrimrPix finds the quality that fits

FORMATS
• JPEG, PNG, and HEIC
• Each photo keeps its original format

METADATA CONTROL
• Choose what the compressed photo keeps: date and time, GPS location, camera settings, copyright info, and Apple data
• Photos keeps its own record of where each photo was taken, so turning GPS off doesn't remove the location from your library

PRIVATE BY DEFAULT
• Everything happens on your device
• No internet connection required
• No cloud, no accounts, no sign-ups
• The only data collected is anonymous crash reports

WORKS WITH ICLOUD
• iCloud photos are downloaded, compressed, and saved back

Compressing replaces the photo in your library, so TrimrPix shows the estimated saving first and asks you to slide to confirm before anything changes.

TrimrPix is open source. There is also a Mac version with a few extra features.
```

### da
```
Jeg byggede TrimrPix til at gøre én ting godt. Den gør billederne i dit iPhone-fotobibliotek mindre og erstatter originalerne direkte. Der er intet dublet-album at rydde op i bagefter, intet uploades, og der kræves ingen internetforbindelse.

Vælg dine billeder, vælg indstillinger, skub for at bekræfte.

Engangskøb. Ingen abonnement, ingen reklamer, ingen sporing.

TO MÅDER AT KOMPRIMERE PÅ
• Kvalitet: Samme, God eller Mindre
• Målstørrelse: sæt en grænse pr. billede (500 KB, 1 MB, 2 MB, 5 MB eller en størrelse, du selv skriver), og TrimrPix finder den kvalitet, der passer

FORMATER
• JPEG, PNG og HEIC
• Hvert billede beholder sit oprindelige format

METADATA-KONTROL
• Vælg, hvad det komprimerede billede beholder: dato og tid, GPS-placering, kameraindstillinger, ophavsret og Apple-data
• Fotos gemmer selv, hvor hvert billede er taget, så placeringen forsvinder ikke fra dit bibliotek, når du slår GPS fra

PRIVAT SOM STANDARD
• Alt sker på din enhed
• Ingen internetforbindelse påkrævet
• Ingen sky, ingen konti, ingen tilmelding
• De eneste data, der indsamles, er anonyme nedbrudsrapporter

VIRKER MED ICLOUD
• iCloud-billeder downloades, komprimeres og gemmes tilbage

Komprimering erstatter billedet i dit bibliotek, så TrimrPix viser den anslåede besparelse først og beder dig skubbe for at bekræfte, før noget ændres.

TrimrPix er open source. Der findes også en Mac-version med et par ekstra funktioner.
```

### de-DE
```
Ich habe TrimrPix entwickelt, um eine Sache gut zu machen. Es verkleinert die Fotos in deiner iPhone-Mediathek und ersetzt die Originale direkt. Es gibt hinterher kein doppeltes Album zum Aufräumen, nichts wird hochgeladen, und es ist keine Internetverbindung nötig.

Fotos auswählen, Einstellungen wählen, zum Bestätigen wischen.

Einmaliger Kauf. Kein Abo, keine Werbung, kein Tracking.

ZWEI ARTEN ZU KOMPRIMIEREN
• Qualität: Gleich, Gut oder Kleiner
• Zielgröße: Lege ein Limit pro Foto fest (500 KB, 1 MB, 2 MB, 5 MB oder eine eigene Größe), und TrimrPix findet die passende Qualität

FORMATE
• JPEG, PNG und HEIC
• Jedes Foto behält sein ursprüngliches Format

METADATEN-KONTROLLE
• Wähle, was das komprimierte Foto behält: Datum und Uhrzeit, GPS-Standort, Kameraeinstellungen, Copyright und Apple-Daten
• Fotos speichert selbst, wo jedes Foto aufgenommen wurde. Wenn du GPS ausschaltest, verschwindet der Standort also nicht aus deiner Mediathek

STANDARDMÄSSIG PRIVAT
• Alles passiert auf deinem Gerät
• Keine Internetverbindung erforderlich
• Keine Cloud, keine Konten, keine Anmeldung
• Erfasst werden nur anonyme Absturzberichte

FUNKTIONIERT MIT ICLOUD
• iCloud-Fotos werden heruntergeladen, komprimiert und zurückgespeichert

Komprimieren ersetzt das Foto in deiner Mediathek. Deshalb zeigt TrimrPix zuerst die geschätzte Ersparnis und bittet dich, zum Bestätigen zu wischen, bevor sich etwas ändert.

TrimrPix ist Open Source. Es gibt auch eine Mac-Version mit ein paar zusätzlichen Funktionen.
```

### fr-FR
```
J'ai conçu TrimrPix pour faire une seule chose, bien. Il réduit la taille des photos de votre photothèque iPhone et remplace les originaux directement. Il ne reste aucun album en double à nettoyer, rien n'est envoyé en ligne, et aucune connexion Internet n'est nécessaire.

Choisissez vos photos, réglez les options, glissez pour confirmer.

Achat unique. Sans abonnement, sans publicité, sans suivi.

DEUX FAÇONS DE COMPRESSER
• Qualité : Identique, Bonne ou Plus petite
• Taille cible : fixez une limite par photo (500 Ko, 1 Mo, 2 Mo, 5 Mo ou une taille de votre choix) et TrimrPix trouve la qualité qui convient

FORMATS
• JPEG, PNG et HEIC
• Chaque photo conserve son format d'origine

CONTRÔLE DES MÉTADONNÉES
• Choisissez ce que la photo compressée conserve : date et heure, position GPS, réglages de l'appareil, droits d'auteur et données Apple
• Photos garde sa propre trace du lieu de chaque photo : désactiver le GPS ne retire donc pas la position de votre photothèque

PRIVÉ PAR DÉFAUT
• Tout se passe sur votre appareil
• Aucune connexion Internet requise
• Aucun cloud, aucun compte, aucune inscription
• Les seules données collectées sont des rapports de plantage anonymes

FONCTIONNE AVEC ICLOUD
• Les photos iCloud sont téléchargées, compressées et réenregistrées

La compression remplace la photo dans votre photothèque ; TrimrPix affiche donc l'économie estimée d'abord et vous demande de glisser pour confirmer avant tout changement.

TrimrPix est open source. Il existe aussi une version Mac avec quelques fonctions supplémentaires.
```

### ja
```
TrimrPixは、ひとつのことをうまくこなすために作りました。iPhoneの写真ライブラリ内の写真を小さくし、元の写真をその場で置き換えます。あとで整理する重複アルバムはできず、どこにもアップロードされず、インターネット接続も不要です。

写真を選び、設定を選び、スライドして確定するだけです。

買い切り。サブスクリプションなし、広告なし、トラッキングなし。

2つの圧縮方法
• 画質：同じ／標準／小さく
• 目標サイズ：写真ごとの上限（500 KB、1 MB、2 MB、5 MB、または自分で入力したサイズ）を設定すると、TrimrPixが最適な画質を見つけます

対応フォーマット
• JPEG、PNG、HEIC
• 各写真は元のフォーマットのまま

メタデータの管理
• 圧縮後の写真に残す情報を選べます：日時、GPS位置情報、カメラ設定、著作権情報、Appleのデータ
• 写真アプリは撮影場所を独自に記録しているため、GPSをオフにしてもライブラリから位置情報は消えません

プライバシー重視
• すべて端末上で処理
• インターネット接続は不要
• クラウドなし、アカウントなし、登録なし
• 収集するのは匿名のクラッシュレポートのみ

iCloudに対応
• iCloudの写真はダウンロードして圧縮し、元に戻して保存します

圧縮するとライブラリ内の写真が置き換えられます。そのためTrimrPixはまず推定の削減量を表示し、変更前にスライドでの確定を求めます。

TrimrPixはオープンソースです。macOS版もあり、いくつか追加機能があります。
```

---

## What's New in 1.5.1

**en-AU**
```
WebP photos are now left as they are and listed as Skipped. iOS can open WebP but can't save it, so they used to fail.

In Target size mode, photos already under your target are now left alone, as the settings screen says. Before, they were saved again anyway.

The saving shown after compressing is now worked out from the photo in your library. A photo is also never replaced with a bigger file: if compressing wouldn't make it smaller, it's left as it is.
```
**da**
```
WebP-billeder bliver nu ladt i fred og vist som Sprunget over. iOS kan åbne WebP, men ikke gemme det, så før fejlede de.

I Målstørrelse-tilstand bliver billeder, der allerede er under din målstørrelse, nu ladt i fred, som indstillingerne siger. Før blev de gemt igen alligevel.

Besparelsen, der vises efter komprimering, regnes nu ud fra billedet i dit bibliotek. Et billede bliver heller aldrig erstattet af en større fil: hvis komprimering ikke ville gøre det mindre, bliver det ladt i fred.
```
**de-DE**
```
WebP-Fotos bleiben jetzt unverändert und erscheinen als „Übersprungen“. iOS kann WebP öffnen, aber nicht speichern, deshalb schlugen sie bisher fehl.

Im Modus „Zielgröße“ bleiben Fotos, die schon unter deiner Zielgröße liegen, jetzt unberührt, wie es die Einstellungen sagen. Bisher wurden sie trotzdem neu gespeichert.

Die Ersparnis nach dem Komprimieren wird jetzt anhand des Fotos in deiner Mediathek berechnet. Außerdem wird ein Foto nie durch eine größere Datei ersetzt: Würde es durch das Komprimieren nicht kleiner, bleibt es unverändert.
```
**fr-FR**
```
Les photos WebP restent désormais telles quelles et apparaissent comme « Ignorées ». iOS sait ouvrir le WebP mais pas l'enregistrer, elles échouaient donc jusqu'ici.

En mode Taille cible, les photos déjà sous votre taille cible ne sont plus touchées, comme l'indiquent les réglages. Jusqu'ici, elles étaient tout de même réenregistrées.

L'économie affichée après la compression est désormais calculée à partir de la photo de votre photothèque. De plus, une photo n'est jamais remplacée par un fichier plus lourd : si la compression ne la rend pas plus légère, elle reste telle quelle.
```
**ja**
```
WebPの写真はそのまま残し、「スキップ」と表示するようになりました。iOSはWebPを開けますが保存できないため、これまでは失敗していました。

目標サイズモードでは、すでに目標サイズ以下の写真に手を加えないようになりました。設定画面の説明どおりの動作です。

圧縮後に表示する削減量は、ライブラリ内の写真をもとに計算するようになりました。また、写真をより大きなファイルで置き換えることはありません。圧縮しても小さくならない場合は、そのまま残します。
```

---

## Screenshots

English only, shared by all five locales, as now. Captured on 2026-10-21 from the final 1.5.1
build (build 2, with #73, #74, #76 and #77) in the iOS 26.5 simulator: light mode, status bar at 9:41. One run
per device, the same three photos at Target size 1 MB, so the frames agree with each other.
Composed with the hub's `tools/appstore_screenshots.py`, with the captions and order from
`appstore/screenshots/README.md`.

| Device | Files | Size | On the listing |
|---|---|---|---|
| iPhone 6.9" | `appstore/screenshots/6.9-inch/1.png` … `4.png` | 1320 × 2868 | Goes in the 6.9" slot, which the listing doesn't have yet. `Preview 01` … `06` in the 6.5" slot come off. |
| iPad 13" | `appstore/screenshots/13-inch-ipad/1.png` … `4.png` | 2064 × 2752 | Replaces the five April simulator shots. |

The raw captures are next to them, in `raw/` (iPhone) and `raw-ipad/`. All eight posters are
RGB with no alpha channel.

The hub places them with:

```
tools/asc_assets.py put --replace --drop iphone-6.5
```

Apple scales the 6.9" set down for the smaller iPhone sizes, so the 6.5" slot isn't needed.

The run's result screen has no Skipped row, because none of the three photos was already under
1 MB. The stock HEIC photo was left out on purpose: in the simulator it takes the
delete-and-recreate path, which adds a Replaced row and a confirmation sheet to the run.

---

## Checked and left alone, for the owner

Not changed in this draft, because each one is a decision rather than a correction:

- **"$1.99" in the en-AU description.** en-AU is the primary language, so this text also serves
  storefronts where the price isn't US$1.99, Australia's included. The other four locales already
  say "one-time purchase" without a price.
- **The space claims, pending a test on a device.** The da, de-DE and fr-FR subtitles ("frigør
  plads", "spart Platz", "libère l'espace"), the ja name (容量節約) and the en-AU keyword "space"
  say the app frees space. In the simulator, compressing in place made the library larger,
  because Photos keeps each original. Check that on a device with the 1.5.1 TestFlight build
  before the hub fills these fields. If it holds, name, subtitle and keywords get a new set from
  the hub, designed as one set as always.
- **"resize"** in the en-AU keywords. The app never changes a photo's pixel dimensions.
