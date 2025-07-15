import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Color palette
const Color kPrimaryColor = Color(0xFF3B5998);
const Color kSecondaryColor = Color(0xFF8B9DC3);
const Color kAccentColor = Color(0xFFF7B32B);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

/// Root widget with injected SharedPreferences
class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: kPrimaryColor,
        secondary: kSecondaryColor,
        surface: Colors.white,
        onSurface: Colors.black,
        error: Colors.red,
        // 'background' and 'onBackground' are deprecated, use 'surface'/'onSurface' instead.
        // background: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        // onBackground: Colors.black,
        onError: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        elevation: 0,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: kPrimaryColor,
        unselectedLabelColor: kSecondaryColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: kAccentColor, width: 2),
          insets: EdgeInsets.symmetric(horizontal: 16.0),
        ),
      ),
      iconTheme: const IconThemeData(color: kPrimaryColor),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: kAccentColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: kAccentColor, foregroundColor: Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kAccentColor,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audiobook Store',
      theme: theme,
      home: MainTabView(prefs: prefs),
    );
  }
}

/// Main tab controller with Store, Library, and Player
class MainTabView extends StatefulWidget {
  final SharedPreferences prefs;
  const MainTabView({super.key, required this.prefs});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Selected audiobook in player
  Audiobook? _selectedBook;
  // Library as list of Audiobook ids
  Set<String> _libraryIds = {};
  // Audiobook catalog (would be loaded from API, here hardcoded demo data)
  final List<Audiobook> _catalog = sampleAudiobooks;

  // Playback progress mapping: bookId -> position in seconds
  late Map<String, double> _playbackPositions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initial library and playback progress load
    _libraryIds = (widget.prefs.getStringList('library') ?? []).toSet();
    _playbackPositions = {
      for (final e in (widget.prefs.getStringList('playbacks') ?? []))
        e.split('|')[0]: double.tryParse(e.split('|')[1]) ?? 0.0
    };
    // Auto-select first book in library (if any)
    if (_libraryIds.isNotEmpty) {
      _selectedBook = _catalog.firstWhere(
        (b) => _libraryIds.contains(b.id),
        orElse: () => _catalog.first,
      );
    }
  }

  Future<void> _saveLibrary() async {
    await widget.prefs.setStringList('library', _libraryIds.toList());
  }

  Future<void> _savePlaybacks() async {
    final entries = _playbackPositions.entries
        .map((e) => '${e.key}|${e.value.toStringAsFixed(2)}')
        .toList();
    await widget.prefs.setStringList('playbacks', entries);
  }

  // PUBLIC_INTERFACE
  void purchaseAudiobook(Audiobook book) {
    /// Purchase an audiobook, add to library and persist
    setState(() {
      _libraryIds.add(book.id);
    });
    _saveLibrary();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Purchased "${book.title}"')),
    );
  }

  // PUBLIC_INTERFACE
  void selectBookForPlayer(Audiobook book) {
    /// Select audiobook for player tab and switch UI
    setState(() {
      _selectedBook = book;
    });
    _tabController.animateTo(2);
  }

  // PUBLIC_INTERFACE
  void updatePlaybackPosition(String bookId, double posSeconds) {
    /// Store new playback position for a given book
    setState(() {
      _playbackPositions[bookId] = posSeconds;
    });
    _savePlaybacks();
  }

  double getPlaybackPosition(String bookId) {
    return _playbackPositions[bookId] ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Three tabs: Store, Library, Player
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Audiobook Store',
          style:
              TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kAccentColor,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: "Store"),
            Tab(icon: Icon(Icons.library_books), text: "Library"),
            Tab(icon: Icon(Icons.headphones), text: "Player"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StoreTab(
            catalog: _catalog,
            libraryIds: _libraryIds,
            onPurchase: purchaseAudiobook,
            onOpen: selectBookForPlayer,
          ),
          LibraryTab(
            audiobooks: _catalog.where((b) => _libraryIds.contains(b.id)).toList(),
            onOpen: selectBookForPlayer,
            playbackPositions: _playbackPositions,
          ),
          PlayerTab(
            book: _selectedBook,
            playbackPositionSeconds: _selectedBook != null
                ? getPlaybackPosition(_selectedBook!.id)
                : 0.0,
            onPositionChanged: updatePlaybackPosition,
            key: ValueKey(_selectedBook?.id ?? 'player'),
          ),
        ],
      ),
    );
  }
}

/// Audiobook Data Structure
class Audiobook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double durationSeconds; // Total length (for demo)
  const Audiobook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.durationSeconds,
  });
}

/// Dummy catalog
const sampleAudiobooks = [
  Audiobook(
    id: 'a1',
    title: 'The Art of Flutter',
    author: 'Jane Doe',
    coverUrl: 'https://covers.openlibrary.org/b/id/13518277-L.jpg',
    durationSeconds: 5380,
  ),
  Audiobook(
    id: 'a2',
    title: 'Mysteries of the Mind',
    author: 'John Smith',
    coverUrl: 'https://covers.openlibrary.org/b/id/13518327-L.jpg',
    durationSeconds: 6450,
  ),
  Audiobook(
    id: 'a3',
    title: 'Minimalism 101',
    author: 'Sara Lee',
    coverUrl: 'https://covers.openlibrary.org/b/id/13518667-L.jpg',
    durationSeconds: 4870,
  ),
];

/// Store Tab UI (catalog & purchase)
class StoreTab extends StatelessWidget {
  final List<Audiobook> catalog;
  final Set<String> libraryIds;
  final Function(Audiobook) onPurchase;
  final Function(Audiobook) onOpen;
  const StoreTab({
    super.key,
    required this.catalog,
    required this.libraryIds,
    required this.onPurchase,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      itemCount: catalog.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, idx) {
        final book = catalog[idx];
        final owned = libraryIds.contains(book.id);
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                book.coverUrl,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 84,
                  color: kSecondaryColor.withAlpha((255 * 0.2).round()),
                  child: const Icon(Icons.image),
                ),
                width: 60,
                height: 84,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(book.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text(book.author),
            trailing: owned
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text("Open"),
                    onPressed: () => onOpen(book),
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                    label: const Text("Buy"),
                    onPressed: () => onPurchase(book),
                  ),
          ),
        );
      },
    );
  }
}

/// Library Tab UI (list purchased audiobooks)
class LibraryTab extends StatelessWidget {
  final List<Audiobook> audiobooks;
  final Map<String, double> playbackPositions;
  final Function(Audiobook) onOpen;
  const LibraryTab({
    super.key,
    required this.audiobooks,
    required this.onOpen,
    required this.playbackPositions,
  });

  String durationFormat(double seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    } else {
      return '${m}m ${s.toStringAsFixed(0).padLeft(2, '0')}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (audiobooks.isEmpty) {
      return const Center(
        child: Text(
          'No audiobooks purchased yet.\nBrowse the store to get started!',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18, color: kSecondaryColor, fontWeight: FontWeight.w500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      itemCount: audiobooks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, idx) {
        final book = audiobooks[idx];
        final double pos = playbackPositions[book.id] ?? 0.0;

        return Card(
          elevation: 1.4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                book.coverUrl,
                width: 48,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 64,
                  color: kSecondaryColor.withAlpha((255 * 0.2).round()),
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            title: Text(book.title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.author, style: const TextStyle(fontSize: 13)),
                if (pos > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'Progress: ${durationFormat(pos)} / ${durationFormat(book.durationSeconds)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kAccentColor,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: kPrimaryColor),
              onPressed: () => onOpen(book),
            ),
          ),
        );
      },
    );
  }
}

/// Player Tab UI (Simulate audio playing)
class PlayerTab extends StatefulWidget {
  final Audiobook? book;
  final double playbackPositionSeconds;
  final Function(String, double) onPositionChanged;

  const PlayerTab({
    required Key key,
    required this.book,
    required this.playbackPositionSeconds,
    required this.onPositionChanged,
  }) : super(key: key);

  @override
  State<PlayerTab> createState() => _PlayerTabState();
}

class _PlayerTabState extends State<PlayerTab> {
  late double position;
  bool isPlaying = false;
  late final Audiobook? book;
  @override
  void initState() {
    super.initState();
    book = widget.book;
    position = widget.playbackPositionSeconds;
  }

  void _seekRel(double deltaSeconds) {
    if (book == null) return;
    setState(() {
      position = (position + deltaSeconds)
          .clamp(0.0, book!.durationSeconds.toDouble());
    });
    widget.onPositionChanged(book!.id, position);
  }

  void _setPlayback(double newPos) {
    if (book == null) return;
    setState(() {
      position = newPos.clamp(0.0, book!.durationSeconds.toDouble());
    });
    widget.onPositionChanged(book!.id, position);
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  String durationFormat(double seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = (seconds % 60).toInt();
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    } else {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return const Center(
        child: Text(
          "Select an audiobook from your library to start listening!",
          style: TextStyle(
              fontSize: 18, color: kSecondaryColor, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      );
    }
    // Removed unused percent variable (was: double percent = position / book!.durationSeconds;)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cover Image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withAlpha((255 * 0.08).round()),
                  blurRadius: 12,
                  spreadRadius: 3,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                book!.coverUrl,
                height: 180,
                width: 135,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 135,
                  height: 180,
                  color: kSecondaryColor.withAlpha((255 * 0.2).round()),
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(book!.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 22, color: kPrimaryColor)),
          Text(book!.author,
              style: const TextStyle(fontSize: 15, color: kSecondaryColor)),
          const SizedBox(height: 18),
          // Progress bar
          Column(
            children: [
              Slider(
                min: 0.0,
                max: book!.durationSeconds,
                value: position,
                onChanged: (v) => _setPlayback(v),
                activeColor: kAccentColor,
                thumbColor: kAccentColor,
                inactiveColor: kSecondaryColor.withAlpha((255 * 0.15).round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(durationFormat(position),
                      style: const TextStyle(color: kSecondaryColor)),
                  Text(durationFormat(book!.durationSeconds),
                      style: const TextStyle(color: kSecondaryColor)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.rotate_left),
                color: kAccentColor,
                iconSize: 36,
                tooltip: 'Back 15 sec',
                onPressed: () => _seekRel(-15),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'playPause',
                backgroundColor: isPlaying ? kAccentColor : kPrimaryColor,
                elevation: 2,
                onPressed: () {
                  _togglePlayPause();
                  // Simulate playback progress
                  if (isPlaying && book != null) {
                    Future.doWhile(() async {
                      if (!mounted ||
                          !isPlaying ||
                          position >= book!.durationSeconds) {
                        setState(() => isPlaying = false);
                        return false;
                      }
                      await Future.delayed(const Duration(seconds: 1));
                      if (!isPlaying) return false;

                      setState(() {
                        position = (position + 1)
                            .clamp(0.0, book!.durationSeconds);
                      });
                      widget.onPositionChanged(book!.id, position);
                      return position < book!.durationSeconds;
                    });
                  }
                },
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.rotate_right),
                color: kAccentColor,
                iconSize: 36,
                tooltip: 'Forward 15 sec',
                onPressed: () => _seekRel(15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
