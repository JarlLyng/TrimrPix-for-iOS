# TrimrPix for iOS — Produktspecifikation

Koncept, brugeroplevelse og funktionelle krav. Teknisk opbygning: [architecture.md](architecture.md).

## Koncept

TrimrPix for iOS komprimerer billeder fra brugerens fotobibliotek. Én opgave: gøre filer mindre uden unødig kompleksitet. Alt foregår lokalt på enheden.

## Brugerflow

1. **Vælg billeder**: multi-select via PhotosPicker (kræver ingen rettigheder). Antal og samlet størrelse vises.
2. **Konfigurer**: vælg kvalitet og metadata-indstillinger. Estimeret besparelse beregnes løbende.
3. **Bekræft**: oversigt over valg + advarsel om at originaler erstattes permanent. Bekræftes med slide-to-confirm. Hvis fotoadgang mangler, vises alert med "Open Settings".
4. **Komprimering**: progressvisning med cirkulær indikator (billede X af Y). Kan annulleres.
5. **Resultat**: antal komprimerede, samlet besparelse, gennemsnitlig besparelse. Ved fejl vises fejl pr. billede. Billeder, der er sprunget over, vises som *Skipped* med én forklaring pr. årsag og tæller ikke som fejl (se [Billeder der springes over](#billeder-der-springes-over)). Ved fuld succes kan App Store-anmeldelse foreslås.

Brugergrænsefladen er på **engelsk**.

## Komprimeringstilstande

Brugeren vælger mellem to tilstande i Konfigurer-trinnet:

- **Quality**: fast kvalitetsniveau (se nedenfor).
- **Target size**: en mål-filstørrelse **pr. billede** (500 KB / 1 MB / 2 MB / 5 MB eller en selvvalgt størrelse). Tjenesten binær-søger lossy-kvaliteten (JPEG/HEIC) eller reducerer paletten (PNG) for at ramme målet. Billeder, der allerede er på eller under målet, springes over og røres ikke: ingen genkodning og ingen redigering i Photos. Rammes målet ikke selv ved laveste kvalitet, bruges det mindst mulige resultat (faktisk størrelse vises altid i resultatet). Det er et **pr.-billede**-budget, ikke et samlet batch-budget.

## Kvalitetsniveauer

| Niveau | Kvalitet | Beskrivelse | Typisk besparelse |
|--------|----------|-------------|-------------------|
| Same | 0.95 | Ingen synlig kvalitetsforringelse | 5–15% |
| Good | 0.80 | Let komprimering, svær at se forskel | 30–50% |
| Smaller | 0.60 | Mere aggressiv, synlig ved zoom | 60–80% |

## Outputformat

TrimrPix komprimerer **JPEG**, **PNG** og **HEIC**. Hvert billede **bevarer sit oprindelige format**, og formatet vælges ikke af brugeren. Det er en bevidst konsekvens af in-place-erstatning: Photos afviser commits hvor det renderede billedes format ikke matcher assetets oprindelige resource-UTI (`PHPhotosErrorInvalidResource`, 3302). Formatkonvertering hører til macOS-søsterappen.

PNG bruger median-cut farve-kvantisering ved Good/Smaller for at reducere filstørrelse.

**WebP** kan læses, men ikke skrives: ImageIO har ingen WebP-encoder på iOS (`CGImageDestinationCopyTypeIdentifiers()` har ingen WebP-post). Et WebP-billede springes derfor over. Tjekket sker ved kørsel (`CompressionService.canEncode`), så en iOS-version med WebP-encoder vil komprimere WebP uden kodeændring.

### Billeder der springes over

Før der skrives noget, afgør tre tjek, om et billede skal lades være (#71): `CompressionService.formatSkipReason` på pickerens bytes, før der røres ved Photos, `CompressionService.targetSkipReason` på størrelsen af billedets aktuelle version i biblioteket (`PHImageManager`, `version = .current`), og efter komprimeringen `CompressionService.shrinkSkipReason`, som sammenligner det komprimerede resultat med samme biblioteksstørrelse. Ikke `PHContentEditingInput.fullSizeImageURL`: appen accepterer alle tidligere justeringer, så den URL peger på den uredigerede original. Pickerens bytes kan være en genkodet kopi med en anden størrelse (en JPEG på 1,27 MB kom som 993 KB, en HEIC på 2,8 MB som 4,1 MB), så de bruges ikke til at måle med.

`compress` beholder selv originalen, hvis resultatet bliver større, men det sammenligner med pickerens kopi. Er den kopi større end bibliotekets fil, kan resultatet være mindre end kopien og stadig større end billedet i biblioteket. Uden det tredje tjek gik HEIC'en ovenfor gennem fallback og kom tilbage som 3,0 MB.

| Årsag | Hvornår | Besked på resultatskærmen |
|-------|---------|---------------------------|
| `formatNotWritable` | Formatet kan læses, men ikke skrives på enheden (i dag WebP) | *iOS can open WebP photos but can't save them, so they were left as they are.* |
| `alreadyUnderTarget` | Target size, og billedet er allerede på eller under målet | *Photos already under the target size were left as they are.* |
| `wouldNotShrink` | Det komprimerede resultat er ikke mindre end billedet i biblioteket | *Photos that wouldn't get any smaller were left as they are.* |

Et billede, der springes over, ændres ikke i biblioteket. Det tæller hverken som komprimeret eller som fejl og rapporteres ikke til Sentry. Estimatet regner det som uændret. Da intet skrives, beholder et billede, der springes over, også sine metadata, selv om brugeren har slået en kategori fra.

### Hvor besparelsen måles fra

Resultatskærmens *Space saved* og *Avg. savings* og den samlede besparelse over tid regnes fra billedets aktuelle version i biblioteket, målt lige før redigeringen (`SizeChange`, `ImageItem.librarySize`). Pickerens bytetal bruges kun, hvis Photos ikke kan give en størrelse. Et billede, der ikke ville blive mindre, springes over (`wouldNotShrink`) og tæller ikke med. `SizeChange` regner desuden et større resultat som 0 sparet.

Estimatet og den samlede størrelse i Konfigurer-trinnet regnes stadig fra pickerens bytes. De vises, før appen har bedt om fotoadgang (pickeren kræver ingen), og bibliotekets størrelser kan ikke læses uden. Estimatet kan derfor afvige, hvor pickeren leverer en genkodet kopi.

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
- Format der ikke kan skrives (WebP), eller billede allerede under målet: springes over, ikke en fejl
- Erstatning fejlet → brugervenlig besked med recovery-forslag
- Annullering → delvis resultat vises
