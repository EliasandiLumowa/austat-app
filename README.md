# Audio Statistik (AuStats) - Mobile Frontend

Aplikasi mobile resmi untuk **Audio Statistik BPS Sulawesi Utara** berbasis Flutter/Dart. Desain dan fungsionalitas antarmuka (frontend) dibuat 100% identik dengan tampilan web AuStats (khusus untuk pengguna publik / non-admin).

---

## 📱 Fitur Utama (100% Identik dengan Web)

1. **Beranda (Home)**:
   - **Hero Section**: Ikon audio volume melingkar, salam selamat datang, penjelasan aksesibilitas tunanetra, dan tombol utama **"Mulai Pencarian Suara"**.
   - **Indikator Statistik (12 Indikator Resmi BPS Sulut)**: Pertumbuhan Ekonomi, Inflasi, Nilai Tukar Petani (NTP), Ekspor & Impor, Transportasi, Pariwisata, IPM, Pertanian, Ketenagakerjaan, Kemiskinan, Industri, dan Kependudukan. Menampilkan jumlah dokumen tersedia dan filter sekali sentuh.
   - **Dokumen Terbaru**: Kartu dokumen dengan rasio sampul 3:4, badge tipe (Publikasi / BRS), nomor urut, tombol putar cepat, dan tombol detail.
   - **Fitur Aksesibilitas**: Text-to-Speech, Pencarian Suara, Navigasi Ramah Aksesibilitas, dan Screen Reader Friendly.
   - **Footer Lengkap**: Tautan cepat, tautan ke portal resmi BPS Sulut (`sulut.bps.go.id`), dan daftar checklist aksesibilitas.

2. **Publikasi (Publications)**:
   - Header dan pengantar resmi.
   - Filter pencarian judul publikasi.
   - Filter tahun dinamis (2025, 2024, 2023, dst.).
   - Filter berdasarkan indikator statistik.
   - Banner jumlah publikasi dan tombol reset filter.

3. **BRS (Berita Resmi Statistik)**:
   - Header Berita Resmi Statistik dengan aksen warna hijau BRS khas BPS.
   - Filter pencarian, filter tahun, dan indikator.
   - Grid kartu dokumen BRS dengan aksi putar dan detail.

4. **Pencarian Komprehensif (Search)**:
   - Pencarian kata kunci dengan teks atau suara.
   - Filter tipe dokumen (Semua Jenis, Publikasi, BRS).
   - Banner indikator perintah suara ("Pencarian Suara: <kata kunci>").
   - Hasil pencarian interaktif.

5. **Spotify-Style Bottom Audio Player (Pemutar Audio Melayang)**:
   - Selalu tersedia di bagian bawah layar saat memutar audio.
   - Thumbnail cover, judul dokumen, durasi berjalan/total durasi, dan format audio (MP3 / FLAC).
   - Kontrol pemutaran: Mundur 10 detik, Play/Pause, Maju 10 detik, Speed rate (1x, 1.25x, 1.5x, 2x), dan Tutup.
   - Dapat dibuka menjadi **Fullscreen Modal Player** dengan cover besar, progress slider, volume, speed, dan transkrip teks audio.

6. **Modal Pencarian Suara Interaktif**:
   - Animasi mikrofon berdenyut (pulse ring animation).
   - Chip contoh perintah suara otomatis (misal: "Pertumbuhan ekonomi 2024", "Inflasi Sulawesi Utara", "BRS kemiskinan").
   - Parsing bahasa alami (NLP) yang langsung mengarahkan ke hasil pencarian.

7. **Detail Dokumen (Show Page / Sidebar Drawer)**:
   - Sampul besar beresolusi tinggi dengan rasio 3:4.
   - Badge tipe, tahun, dan ketersediaan audio.
   - Metadata lengkap (Indikator, tanggal terbit, durasi, total unduhan).
   - Tombol putar audio langsung, unduh MP3, dan unduh FLAC.
   - Ringkasan teks hasil ekstraksi dokumen.

---

## 🚀 Panduan Menjalankan Aplikasi Mobile

### 1. Masuk ke Direktori Mobile
Buka terminal pada folder `austat-mobile/`:
```bash
cd austat-mobile
```

### 2. Mengambil Dependensi
```bash
flutter pub get
```

### 3. Menjalankan Aplikasi

- **Android Emulator**:
  ```bash
  flutter run
  ```
  *(Pada Android emulator, aplikasi secara otomatis terhubung ke backend lokal melalui `http://10.0.2.2:8000`)*

- **Chrome / Web Browser**:
  ```bash
  flutter run -d chrome
  ```

- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

- **Perangkat Fisik (HP Android via USB)**:
  Aktifkan USB Debugging di HP, lalu jalankan:
  ```bash
  flutter run
  ```
  *(Ubah IP backend di `lib/services/api_service.dart` ke IP lokal laptop/komputer Anda, misal `http://192.168.1.x:8000`)*

---

## 🛠️ Struktur Kode (`lib/`)

```
lib/
├── main.dart                          # Titik masuk utama, Shell Scaffold, Bottom Navigation, App Bar & Drawer
├── models/
│   ├── document_model.dart            # Model data dokumen (Publikasi & BRS)
│   └── indicator_model.dart           # Model data indikator statistik
├── services/
│   ├── api_service.dart               # Service komunikasi REST API & data offline/mockup fallback
│   └── audio_service.dart             # State management audio player (ChangeNotifier)
├── theme/
│   └── app_theme.dart                 # Token warna Tailwind web, Inter Google Fonts, & CardThemeData
├── widgets/
│   ├── audio_player_bottom_bar.dart   # Pemutar audio Spotify UI & Fullscreen Player Sheet
│   ├── document_card_widget.dart      # Kartu dokumen rasio 3:4 dengan badge tipe & nomor urut
│   ├── indicator_card_widget.dart     # Kartu indikator statistik dengan ikon biru BPS
│   ├── voice_search_dialog.dart       # Dialog modal pencarian suara animasi pulse
│   └── web_footer_widget.dart         # Footer lengkap identik dengan website
└── screens/
    ├── home_screen.dart               # Halaman Beranda (Hero, Indikator, Dokumen, Aksesibilitas, Footer)
    ├── publications_screen.dart       # Halaman Publikasi dengan filter pencarian & tahun
    ├── brs_screen.dart                # Halaman Berita Resmi Statistik (BRS)
    ├── search_screen.dart             # Halaman Pencarian Multi-Filter & Voice Indicator
    └── document_detail_screen.dart    # Halaman Detail Dokumen & Teks Ekstraksi
```
