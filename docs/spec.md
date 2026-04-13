# TrimrPix for iOS — Produktspecifikation

Koncept, brugeroplevelse og funktionelle krav. Teknisk opbygning: [architecture.md](architecture.md).

## Koncept

TrimrPix for iOS komprimerer billeder fra brugerens fotobibliotek. Én opgave: gøre filer mindre uden unødig kompleksitet. Alt foregår lokalt på enheden — ingen internetforbindelse nødvendig til kernefunktionen.

## Brugerflow

1. **Vælg billeder** — multi-select via PhotosPicker. Antal og samlet størrelse vises.
2. **Konfigurer** — vælg kvalitet, outputformat og metadata-indstillinger. Estimeret besparelse beregnes løbende.
3. **Bekræft** — oversigt over valg + advarsel om at originaler erstattes permanent. Bekræftes med slide-to-confirm gesture.
4. **Komprimering** — progressvisning med cirkulær indikator (billede X af Y). Kan annulleres.
5. **Resultat** — antal komprimerede, samlet besparelse, gennemsnitlig besparelse. Ved fejl vises fejl pr. billede.

Brugergrænsefladen er på **engelsk**.

## Kvalitetsniveauer

| Niveau | Komprimeringskvalitet | Beskrivelse | Typisk besparelse |
|--------|-----------------------|-------------|-------------------|
| Same | 0.95 | Ingen synlig kvalitetsforringelse | 5–15% |
| Good | 0.80 | Let komprimering, svær at se forskel | 30–50% |
| Smaller | 0.60 | Mere aggressiv, synlig ved zoom | 60–80% |

## Outputformat

Vælges pr. batch: **JPEG** (standard), **PNG**, **WebP**, **HEIC**.

PNG bruger median-cut farve-kvantisering ved Good/Smaller for at reducere filstørrelse.

## Metadata

Brugeren vælger hvilke metadata-kategorier der **bevares** (toggle ON = behold, OFF = fjern permanent):

| Kategori | Standard | Indhold |
|----------|----------|---------|
| Date & time | Beholdes | Hvornår billedet blev taget |
| Camera settings | Fjernes | Kameramodel, eksponering, ISO, blænde |
| GPS location | Fjernes | Bredde- og længdegrad, højde |
| Copyright & description | Fjernes | Fotograf, billedtekst, nøgleord (IPTC) |
| Apple data | Fjernes | Live Photo, HDR, burst-info |

## Billedvalg

- Multi-select via `PhotosPicker`
- Ingen hård kodet øvre grænse; store batches begrænses af enhedens hukommelse
- Kræver fuld `.readWrite` adgang til fotobiblioteket (limited access understøttes ikke for skriveoperationer)

## Komprimering og erstatning

- Originalbilleder erstattes **in-place** via Photos-frameworkets content editing API
- Ingen dubletter — billedet modificeres direkte i biblioteket
- Handlingen **kan ikke fortrydes** (advarslen er tydelig i bekræftelsestrinnet)
- Estimeret besparelse beregnes før komprimering starter og opdateres ved ændring af kvalitet, format eller metadata
- Hukommelse frigives løbende under behandling (originaldata slettes efter hvert billede)

## Fejlhåndtering

- Manglende fotoadgang: tydelig fejlbesked
- Billede ikke fundet i bibliotek: pr-billede fejl, øvrige fortsætter
- Komprimeringsfejl: pr-billede fejl med formatspecifik besked
- Annullering: delvis resultat vises

## Begrænsninger

- Kun stillbilleder — ikke video
- Kræver fuld adgang til fotobiblioteket (ikke "limited")
- Ingen internetforbindelse nødvendig til kernefunktionen
- Sentry kræver netværk til crash-rapportering (valgfrit, fejler stille)
