# TrimrPix for iOS — Produktspecifikation

Koncept, brugeroplevelse og funktionelle krav. Teknisk opbygning: [architecture.md](architecture.md).

## Koncept

TrimrPix for iOS komprimerer billeder fra brugerens fotobibliotek. Én opgave: gøre filer mindre uden unødig kompleksitet.

## Brugerflow (oplevelse)

1. Vælg ét eller flere billeder (`PhotosPicker`).
2. Indstil kvalitet, outputformat og hvilke metadata der bevares eller fjernes; estimeret besparelse vises.
3. Bekræft på bekræftelsesskærmen (slide-to-confirm); advarsel om at originaler erstattes og handlingen ikke kan fortrydes.
4. Under komprimering vises fremskridt (billede X af Y).
5. Resultatskærm med antal, samlet besparelse og evt. fejl pr. billede.

*(Brugergrænsefladen i appen er på engelsk.)*

## Kvalitetsniveauer

| Niveau  | Beskrivelse | Typisk besparelse |
|---------|-------------|-------------------|
| Same    | Ingen synlig kvalitetsforringelse; metadata kan stadig styres med toggles | 5–15% |
| Good    | Let komprimering, svær at se forskel | 30–50% |
| Smaller | Mere aggressiv komprimering, synlig ved zoom | 60–80% |

## Outputformat

Vælges pr. batch (ikke pr. billede): **JPEG** (standard), **PNG**, **WebP**, **HEIC**.

## Metadata

Under konfiguration kan brugeren vælge hvad der bevares: dato/tid, kameraindstillinger, GPS, IPTC og Apple maker-note. Alt andet relevant kan fjernes ifølge de valgte toggles.

## Billedvalg

- Multi-select via `PhotosPicker`.
- Ingen hård kodet øvre grænse i appen; meget store batches begrænses af enhedens hukommelse og Fotos-adgang.

## Komprimering og erstatning

- Standard: originalfiler erstattes in-place efter bekræftelse.
- Progress under behandling.
- Besparelse vises som estimeret procent før komprimering startes.

## Begrænsninger

- Kræver adgang til fotobiblioteket.
- Kun stillbilleder — ikke video.
- Ingen internetforbindelse nødvendig til kernefunktionen.
