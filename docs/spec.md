# TrimrPix for iOS — Produktspecifikation

## Koncept

TrimrPix for iOS komprimerer billeder direkte fra brugerens Fotos-app. Appen gør én ting og gør det godt: gør billeder mindre uden unødig kompleksitet.

## Brugerflow

1. **Vælg billeder** — Åbn fotovælger, vælg ét eller flere billeder
2. **Konfigurer** — Vælg kvalitetsniveau og outputformat
3. **Se besparelse** — Estimeret pladsbesparelse vises i procent
4. **Bekræft** — Advarsel: "Dette erstatter originalerne. Vil du fortsætte?"
5. **Komprimer** — Progress-visning mens billeder behandles
6. **Færdig** — Resultat: antal billeder komprimeret, total besparelse

## Kvalitetsniveauer

| Niveau | Beskrivelse | Typisk besparelse |
|--------|-------------|-------------------|
| Same | Ingen synlig kvalitetsforringelse, metadata fjernes | 5-15% |
| Good | Let komprimering, svær at se forskel | 30-50% |
| Smaller | Mere aggressiv komprimering, synlig ved zoom | 60-80% |

## Formatvalg

Brugeren kan vælge outputformat pr. batch (ikke pr. billede):

- **JPEG** — Standard, god til fotos (default)
- **PNG** — Tabsfri, god til skærmbilleder og grafik
- **WebP** — Moderne format, god balance mellem størrelse og kvalitet
- **HEIC** — Apple-format, god komprimering

## Billedvalg

- Multi-select via `PhotosPicker` (SwiftUI PhotosUI)
- Ingen øvre grænse på antal billeder
- Thumbnails vises i grid efter valg

## Komprimering

- Originalbilledet erstattes som default
- Bekræftelsesdialog inden komprimering starter
- Progress-indikator under komprimering (billede X af Y)
- Besparelse vises i procent inden komprimering bekræftes

## Begrænsninger

- Kræver adgang til Fotos-biblioteket
- Video understøttes ikke — kun stillbilleder
- Internetforbindelse er ikke nødvendig
