import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/publications_screen.dart';
import 'screens/brs_screen.dart';
import 'screens/search_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/audio_player_bottom_bar.dart';
import 'widgets/voice_search_dialog.dart';
import 'widgets/voice_accessibility_widget.dart';
import 'services/voice_assistant_service.dart';
import 'services/audio_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const AuStatsMobileApp());
}

class AuStatsMobileApp extends StatelessWidget {
  const AuStatsMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Statistik BPS Sulut',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _activeSearchParams;

  @override
  void initState() {
    super.initState();
    _setupVoiceAssistant();
  }

  void _setupVoiceAssistant() {
    final voice = VoiceAssistantService();
    voice.onIndicatorSelected = (indicator, docs) {
      if (mounted) {
        // Tampilkan halaman daftar dokumen/berita untuk indikator ini
        _triggerSearchWithParams({
          'indicatorId': indicator.id,
          'voicePhrase': indicator.name,
        });
      }
    };
    voice.onPlayDocument = (doc) {
      AudioService().playDocument(doc);
    };
    voice.onNavigateTab = (tabIndex) {
      if (mounted) {
        _onTabSelected(tabIndex);
      }
    };

    // Jalankan sambutan & tutorial otomatis saat aplikasi pertama kali dimulai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      voice.startWelcomeFlow();
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _triggerSearchWithParams(Map<String, dynamic> params) {
    setState(() {
      _activeSearchParams = params;
      _currentIndex = 3; // Switch to Search tab
    });
  }

  void _openVoiceSearch() {
    VoiceSearchDialog.show(
      context,
      onSearchParsed: (parsed) {
        _triggerSearchWithParams(parsed);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- APP BAR (Matching website header) ---
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            // Gradient Icon Box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary600.withAlpha(50),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            // Title & Subtitle
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Audio Statistik',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.gray900,
                  ),
                ),
                Text(
                  'BPS Sulawesi Utara',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Voice Control Quick Action
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: AppTheme.primary600),
            tooltip: 'Kendali Suara (Bicara)',
            onPressed: () {
              VoiceAssistantService().userInterruptedToSpeak();
            },
          ),
          // Search Icon Action
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.gray700),
            tooltip: 'Cari Dokumen',
            onPressed: () => _onTabSelected(3),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // --- DRAWER MENU (Matching website navigation) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: AppTheme.primary600, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Audio Statistik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'BPS Provinsi Sulawesi Utara',
                    style: TextStyle(
                      color: Color(0xFFDBEAFE),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppTheme.primary600),
              title: const Text('Beranda', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: AppTheme.primary600),
              title: const Text('Publikasi', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper_rounded, color: AppTheme.green600),
              title: const Text('BRS (Berita Resmi)', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_rounded, color: AppTheme.primary600),
              title: const Text('Pencarian', style: TextStyle(fontWeight: FontWeight.w600)),
              selected: _currentIndex == 3,
              onTap: () {
                Navigator.pop(context);
                _onTabSelected(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mic_rounded, color: AppTheme.primary600),
              title: const Text('Pencarian Suara'),
              onTap: () {
                Navigator.pop(context);
                _openVoiceSearch();
              },
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Layanan audio statistik aksesibilitas BPS Provinsi Sulawesi Utara.',
                style: TextStyle(fontSize: 11, color: AppTheme.gray400),
              ),
            ),
          ],
        ),
      ),

      // --- BODY WITH VOICE ASSISTANT BANNER & SCREEN SWITCHING ---
      // Sentuh di mana saja saat audio berjalan langsung meng-cut audio & mendengarkan suara user
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final voice = VoiceAssistantService();
          final audio = AudioService();
          if (voice.isSpeaking || audio.isPlaying) {
            voice.cutAudioAndListen();
          }
        },
        child: Column(
          children: [
            // Voice Assistant Accessibility Banner
            const VoiceAccessibilityWidget(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeScreen(
                    onNavigateTab: _onTabSelected,
                    onTriggerSearch: _triggerSearchWithParams,
                  ),
                  const PublicationsScreen(),
                  const BrsScreen(),
                  SearchScreen(
                    initialParams: _activeSearchParams,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- BOTTOM SECTION: SPOTIFY PLAYER & BOTTOM NAV BAR ---
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spotify UI Bottom Player
          const AudioPlayerBottomBar(),

          // Bottom Navigation Bar
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book_rounded),
                label: 'Publikasi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.newspaper_outlined),
                activeIcon: Icon(Icons.newspaper_rounded),
                label: 'BRS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search_rounded),
                label: 'Pencarian',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
