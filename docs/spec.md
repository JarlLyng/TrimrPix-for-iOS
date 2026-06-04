# TrimrPix for iOS — Produktspecifikation

Koncept, brugeroplevelse og funktionelle krav. Teknisk opbygning: [architecture.md](architecture.md).

## Koncept

TrimrPix for iOS komprimerer billeder fra brugerens fotobibliotek. Én opgave: gøre filer mindre uden unødig kompleksitet. Alt foregår lokalt på enheden.

## Brugerflow

1. **Vælg billeder** — multi-select via PhotosPicker (kræver ingen rettigheder). Antal og samlet størrelse vises.
2. **Konfigurer** — vælg kvalitet og metadata-indstillinger. Estimeret besparelse beregnes løbende.
3. **Bekræft** — oversigt over valg + advarsel om at originaler erstattes permanent. Bekræftes med slide-to-confirm. Hvis fotoadgang mangler, vises alert med "Open Settings".
4. **Komprimering** — progressvisning med cirkulær indikator (billede X af Y). Kan annulleres.
5. **Resultat** — antal komprimerede, samlet besparelse, gennemsnitlig besparelse. Ved fejl vises fejl pr. billede. Ved fuld succes kan App Store-anmeldelse foreslås.

Brugergrænsefladen er på **engelsk**.

## Kvalitetsniveauer

| Niveau | Kvalitet | Beskrivelse | Typisk besparelse |
|--------|----------|-------------|-------------------|
| Same | 0.95 | Ingen synlig kvalitetsforringelse | 5–15% |
| Good | 0.80 | Let komprimering, svær at se forskel | 30–50% |
| Smaller | 0.60 | Mere aggressiv, synlig ved zoom | 60–80% |

## Outputformat

TrimrPix understøtter **JPEG**, **PNG**, **WebP** og **HEIC**. Hvert billede komprimeres og **bevarer sit oprindelige format** — formatet vælges ikke af brugeren. Det er en bevidst konsekvens af in-place-erstatning: Photos afviser commits hvor det renderede billedes format ikke matcher assetets oprindelige resource-UTI (`PHPhotosErrorInvalidResource`, 3302). Formatkonvertering hører til macOS-søsterappen.

PNG bruger median-cut farve-kvantisering ved Good/Smaller for at reducere filstørrelse.

## Metadata

Brugeren vælger hvilke metadata-kategorier der **bevares** (toggle ON = behold, OFF = fjern permanent). Forklarende tekst over toggles: *"Choose which metadata to keep. Disabled items will be permanently removed."*

| Kategori | Standard | Indhold |
|----------|----------|---------|
| Date & time | Beholdes | Hvornår billedet blev taget |
| Camera settings | Fjernes | Kameramodel, eksponering, ISO, blænde |
| GPS location | Fjernes | Bredde- og længdegrad, højde |
| Copyright & description | Fjernes | Fotograf, billedtekst, nøgleord (IPTC) |
| Apple data | Fjernes | Live Photo, HDR, burst-info |

## Fotos-adgang

- Billedvalg via `PhotosPicker` kræver **ingen** rettigheder
- Komprimering (skrivning) kræver `.readWrite` adgang — både fuld og begrænset adgang fungerer
- Første gang: system-dialog vises automatisk
- Hvis afvist: alert med "Open Settings" knap guider brugeren

## Komprimering og erstatning

- Originalbilleder erstattes **in-place** via Photos-frameworkets content editing API
- Ingen dubletter — billedet modificeres direkte i biblioteket
- Handlingen **kan ikke fortrydes** (advarslen er tydelig i bekræftelsestrinnet)
- Estimeret besparelse beregnes før komprimering og opdateres ved ændring af kvalitet, format eller metadata
- Hukommelse frigives løbende under behandling
- iCloud-fotos understøttes (downloades automatisk ved behov)

## Fejlhåndtering

- Manglende fotoadgang → alert med "Open Settings" (blokerer komprimering)
- Billede ikke fundet i bibliotek → pr-billede fejl, øvrige fortsætter
- Komprimeringsfejl → pr-billede fejl med formatspecifik besked
- Erstatning fejlet → brugervenlig besked med recovery-forslag
- Annullering → delvis resultat vises
