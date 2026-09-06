import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class BibleLocation {
  final String name;
  final String description;
  final double lat;
  final double lng;

  const BibleLocation({
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
  });
}

class MapScreen extends StatefulWidget {
  final String book;
  final int chapter;

  const MapScreen({super.key, required this.book, required this.chapter});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _settings = SettingsService();
  BibleLocation? _location;
  bool _loading = true;
  String? _error;
  bool _hasApiKey = false;

  // Předdefinované lokace pro rychlé načtení
  static const Map<String, BibleLocation> _knownLocations = {
    'Genesis': BibleLocation(name: 'Mezopotámie / Eden', description: 'Oblast mezi řekami Tigris a Eufrat', lat: 33.0, lng: 44.0),
    'Exodus': BibleLocation(name: 'Egypt / Sinaj', description: 'Egyptská země a sinajský poloostrov', lat: 29.5, lng: 33.0),
    'Joshua': BibleLocation(name: 'Kanaán', description: 'Zaslíbená země Izraele', lat: 31.5, lng: 35.0),
    'Judges': BibleLocation(name: 'Izrael', description: 'Země Izraele v době soudců', lat: 31.5, lng: 35.0),
    'Ruth': BibleLocation(name: 'Betlém / Moáb', description: 'Betlém a moábská krajina', lat: 31.7, lng: 35.2),
    'Psalms': BibleLocation(name: 'Jeruzalém', description: 'Město Davida, centrum izraelského uctívání', lat: 31.77, lng: 35.21),
    'Proverbs': BibleLocation(name: 'Jeruzalém', description: 'Šalamounův Jeruzalém', lat: 31.77, lng: 35.21),
    'Isaiah': BibleLocation(name: 'Jeruzalém', description: 'Jeruzalém v době asyrské hrozby', lat: 31.77, lng: 35.21),
    'Jeremiah': BibleLocation(name: 'Jeruzalém', description: 'Jeruzalém před babylonským zajetím', lat: 31.77, lng: 35.21),
    'Lamentations': BibleLocation(name: 'Jeruzalém', description: 'Zničený Jeruzalém po babylonském vpádu', lat: 31.77, lng: 35.21),
    'Ezekiel': BibleLocation(name: 'Babylón', description: 'Ezechiel prorokoval v babylonském zajetí u řeky Chebar', lat: 32.54, lng: 44.42),
    'Daniel': BibleLocation(name: 'Babylón', description: 'Danielův příběh v babylonském a perském dvoru', lat: 32.54, lng: 44.42),
    'Jonah': BibleLocation(name: 'Ninive', description: 'Asyrské hlavní město kde Jonáš kázal', lat: 36.36, lng: 43.15),
    'Nahum': BibleLocation(name: 'Ninive', description: 'Asyrské hlavní město — cíl Nahuma proroctví soudu', lat: 36.36, lng: 43.15),
    'Habakkuk': BibleLocation(name: 'Judsko', description: 'Abakuk prorokoval v Judsku před babylonským vpádem', lat: 31.5, lng: 35.0),
    'Zephaniah': BibleLocation(name: 'Jeruzalém', description: 'Sofoniáš prorokoval v Judsku za krále Jošiáše', lat: 31.77, lng: 35.21),
    'Haggai': BibleLocation(name: 'Jeruzalém', description: 'Aggeus prorokoval při obnově chrámu po návratu z exilu', lat: 31.77, lng: 35.21),
    'Zechariah': BibleLocation(name: 'Jeruzalém', description: 'Zachariáš prorokoval při obnově Jeruzaléma', lat: 31.77, lng: 35.21),
    'Malachi': BibleLocation(name: 'Jeruzalém', description: 'Malachiáš — poslední prorok Starého zákona', lat: 31.77, lng: 35.21),
    'Obadiah': BibleLocation(name: 'Edóm', description: 'Abdiáš prorokoval proti Edómu jižně od Mrtvého moře', lat: 30.5, lng: 35.5),
    'Joel': BibleLocation(name: 'Judsko', description: 'Joel prorokoval v Judsku', lat: 31.77, lng: 35.21),
    'Amos': BibleLocation(name: 'Severní Izrael', description: 'Ámos prorokoval v Betelu a Samaří', lat: 32.27, lng: 35.2),
    'Matthew': BibleLocation(name: 'Galilej / Jeruzalém', description: 'Ježíšova služba v Galileji a Judsku', lat: 32.7, lng: 35.5),
    'Mark': BibleLocation(name: 'Galilej', description: 'Ježíšova aktivní služba v Galileji', lat: 32.7, lng: 35.5),
    'Luke': BibleLocation(name: 'Judsko / Galilej', description: 'Ježíšův život od Betléma po Jeruzalém', lat: 31.9, lng: 35.2),
    'John': BibleLocation(name: 'Judsko / Galilej', description: 'Janovo evangelium — Ježíšova služba', lat: 31.77, lng: 35.21),
    'Acts': BibleLocation(name: 'Jeruzalém / Řím', description: 'Šíření evangelia od Jeruzaléma po Řím', lat: 41.9, lng: 12.5),
    'Romans': BibleLocation(name: 'Řím', description: 'Pavlův dopis křesťanům v Římě', lat: 41.9, lng: 12.5),
    '1 Corinthians': BibleLocation(name: 'Korint', description: 'Řecké město Korint kde Pavel zakládal církev', lat: 37.91, lng: 22.88),
    '2 Corinthians': BibleLocation(name: 'Korint', description: 'Řecké město Korint', lat: 37.91, lng: 22.88),
    'Galatians': BibleLocation(name: 'Galácie', description: 'Oblast v centrální Malé Asii (dnešní Turecko)', lat: 39.0, lng: 32.0),
    'Ephesians': BibleLocation(name: 'Efez', description: 'Starověké město Efez v Malé Asii', lat: 37.94, lng: 27.34),
    'Philippians': BibleLocation(name: 'Filipi', description: 'Makedonské město Filipi v Řecku', lat: 41.01, lng: 24.29),
    'Colossians': BibleLocation(name: 'Kolosy', description: 'Město Kolosy v Malé Asii', lat: 37.78, lng: 29.12),
    'Revelation': BibleLocation(name: 'Patmos / Malá Asie', description: 'Jan napsal Zjevení na ostrově Patmos', lat: 37.32, lng: 26.55),
    '1 Samuel': BibleLocation(name: 'Izrael', description: 'Saulovo a Davidovo království', lat: 31.5, lng: 35.0),
    '2 Samuel': BibleLocation(name: 'Jeruzalém', description: 'Davidovo království s hlavním městem Jeruzalémem', lat: 31.77, lng: 35.21),
    '1 Kings': BibleLocation(name: 'Jeruzalém / Izrael', description: 'Šalamounovo království a rozdělení Izraele', lat: 31.77, lng: 35.21),
    '2 Kings': BibleLocation(name: 'Izrael / Judsko', description: 'Pád severního i jižního království', lat: 31.77, lng: 35.21),
    'Hosea': BibleLocation(name: 'Severní Izrael (Samaří)', description: 'Ozeáš prorokoval v severním království', lat: 32.27, lng: 35.2),
    'Micah': BibleLocation(name: 'Judsko', description: 'Micheáš prorokoval v Judsku', lat: 31.5, lng: 34.9),
  };

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() => _loading = true);

    // Zkus předdefinovanou lokaci
    final known = _knownLocations[widget.book];
    if (known != null) {
      setState(() {
        _location = known;
        _loading = false;
      });
      return;
    }

    // Zeptej se AI
    final hasKey = await _settings.hasApiKey();
    if (!hasKey) {
      setState(() {
        _error = null; // will use l10n
        _loading = false;
        _hasApiKey = false;
        _loading = false;
      });
      return;
    }

    try {
      final provider = await _settings.getProvider();
      final apiKey = await _settings.getApiKey();
      final ai = AIService(provider: provider, apiKey: apiKey!);
      final location = await ai.getBibleLocation(widget.book, widget.chapter);
      setState(() {
        _location = location;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor(context)),
      );
    }

    if (!_hasApiKey && _location == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: AppTheme.textSecondaryColor(context), size: 48),
            SizedBox(height: 16),
            Text(l.mapApiRequired,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (_error != null || _location == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: AppTheme.textSecondaryColor(context), size: 48),
            SizedBox(height: 16),
            Text(l.mapNoLocation,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final loc = _location!;
    final point = LatLng(loc.lat, loc.lng);

    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceColor(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.goldColor(context), size: 18),
                  SizedBox(width: 8),
                  Text(
                    loc.name,
                    style: GoogleFonts.cinzel(
                      color: AppTheme.goldColor(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                loc.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Mapa
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 6.0,
            ),
            children: [
              TileLayer(
               urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.jack4xt.bibleday',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor(context),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldColor(context).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(Icons.menu_book,
                              color: Colors.black, size: 20),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: AppTheme.goldColor(context), size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
