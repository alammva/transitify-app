import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const TransitifyApp());
}

// ==================== THEME & CONSTANTS ====================
class AppColors {
  static const Color ecoGreen = Color(0xFF10B981);
  static const Color deepTeal = Color(0xFF075E54);
  static const Color mintLight = Color(0xFFD1FAE5);
  static const Color softGray = Color(0xFFF3F4F6);
  static const Color textDark = Color(0xFF111827);
}

ThemeData buildTransitifyTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.ecoGreen,
    primary: AppColors.ecoGreen,
    secondary: AppColors.deepTeal,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.deepTeal,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ecoGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.softGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.ecoGreen, width: 2),
      ),
    ),
  );
}

class TransitifyApp extends StatelessWidget {
  const TransitifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transitify',
      debugShowCheckedModeBanner: false,
      theme: buildTransitifyTheme(),
      home: const AuthGate(),
    );
  }
}

// ==================== AUTH STATE ====================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  String _language = 'English';
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, _TransitifyAccount> _accounts = {};
  _TransitifyAccount? _activeAccount;

  bool get _isIndonesian => _language == 'Bahasa Indonesia';

  void _setLanguage(String language) => setState(() => _language = language);

  String? _register(String name, String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      return _isIndonesian
          ? 'Email ini sudah terdaftar. Silakan masuk.'
          : 'This email is already registered. Please sign in.';
    }
    _accounts[normalizedEmail] = _TransitifyAccount(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
    );
    return null;
  }

  bool _login(String email, String password) {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) return false;
    setState(() {
      _isLoggedIn = true;
      _activeAccount = account;
    });
    return true;
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _activeAccount = null;
    });
  }

  void _updateProfile(String newName) {
    final account = _activeAccount;
    if (account == null) return;
    setState(() {
      account.name = newName.trim();
    });
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        _showPhotoMessage(
          _isIndonesian
              ? 'File foto kosong atau tidak dapat dibaca.'
              : 'The selected image is empty or could not be read.',
        );
        return;
      }
      if (bytes.length > 8 * 1024 * 1024) {
        _showPhotoMessage(
          _isIndonesian
              ? 'Ukuran foto maksimal 8 MB.'
              : 'The maximum image size is 8 MB.',
        );
        return;
      }
      final account = _activeAccount;
      if (account == null || !mounted) return;
      setState(() => account.profileImage = bytes);
      _showPhotoMessage(
        _isIndonesian
            ? 'Foto profil berhasil diperbarui.'
            : 'Profile picture updated successfully.',
      );
    } on PlatformException catch (error) {
      _showPhotoMessage(
        _isIndonesian
            ? 'Tidak dapat membuka galeri: ${error.message ?? error.code}'
            : 'Could not open the photo library: ${error.message ?? error.code}',
      );
    } on Exception catch (error) {
      _showPhotoMessage(
        _isIndonesian
            ? 'Foto gagal dipilih: $error'
            : 'Could not select image: $error',
      );
    }
  }

  void _showPhotoMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _deleteAccount() {
    final account = _activeAccount;
    if (account == null) return;
    _accounts.remove(account.email);
    _logout();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(
        onLogin: _login,
        onRegister: _register,
        isIndonesian: _isIndonesian,
      );
    }
    final account = _activeAccount!;
    return MainDashboard(
      displayName: account.name,
      username: account.email.split('@').first,
      onLogout: _logout,
      onProfileChanged: _updateProfile,
      onDeleteAccount: _deleteAccount,
      profileImage: account.profileImage,
      onPickProfilePhoto: _pickProfilePhoto,
      language: _language,
      onLanguageChanged: _setLanguage,
    );
  }
}

class _TransitifyAccount {
  String name;
  final String email;
  final String password;
  Uint8List? profileImage;

  _TransitifyAccount({
    required this.name,
    required this.email,
    required this.password,
  });
}

// ==================== LOGIN / REGISTER ====================
class LoginScreen extends StatefulWidget {
  final bool Function(String email, String password) onLogin;
  final String? Function(String name, String email, String password) onRegister;
  final bool isIndonesian;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.isIndonesian,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isRegisterMode = false;
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;
    if (_isRegisterMode) {
      final error = widget.onRegister(_nameCtrl.text.trim(), email, password);
      if (error != null) {
        _showMessage(error);
        return;
      }
      setState(() => _isRegisterMode = false);
      _emailCtrl.text = email;
      _passCtrl.clear();
      _showMessage(
        widget.isIndonesian
            ? 'Akun berhasil dibuat. Silakan masuk dengan akun Anda.'
            : 'Account created. Please sign in with your new account.',
      );
    } else if (!widget.onLogin(email, password)) {
      _showMessage(
        widget.isIndonesian
            ? 'Email atau kata sandi salah. Daftar terlebih dahulu jika belum memiliki akun.'
            : 'Incorrect email or password. Register first if you do not have an account.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 52,
                    color: AppColors.deepTeal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Transitify',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepTeal,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegisterMode
                    ? (widget.isIndonesian
                          ? 'Buat akun mobilitas ramah lingkungan'
                          : 'Create your eco-mobility account')
                    : 'Smart Urban Mobility for Greener Cities',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isRegisterMode) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => (value?.trim().length ?? 0) < 2
                            ? (widget.isIndonesian
                                  ? 'Masukkan nama lengkap'
                                  : 'Enter your full name')
                            : null,
                        decoration: InputDecoration(
                          labelText: widget.isIndonesian
                              ? 'Nama Lengkap'
                              : 'Full Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)) {
                          return widget.isIndonesian
                              ? 'Masukkan alamat email yang valid'
                              : 'Enter a valid email address';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      validator: (value) => (value?.length ?? 0) < 6
                          ? (widget.isIndonesian
                                ? 'Kata sandi minimal 6 karakter'
                                : 'Password must be at least 6 characters')
                          : null,
                      decoration: InputDecoration(
                        labelText: widget.isIndonesian
                            ? 'Kata Sandi'
                            : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _submit,
                child: Text(
                  _isRegisterMode
                      ? (widget.isIndonesian ? 'BUAT AKUN' : 'CREATE ACCOUNT')
                      : (widget.isIndonesian ? 'MASUK' : 'SIGN IN'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isRegisterMode
                        ? (widget.isIndonesian
                              ? 'Sudah punya akun?'
                              : 'Already have an account?')
                        : (widget.isIndonesian
                              ? 'Belum punya akun?'
                              : "Don't have an account?"),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isRegisterMode = !_isRegisterMode),
                    child: Text(
                      _isRegisterMode
                          ? (widget.isIndonesian ? 'Masuk!' : 'Sign In!')
                          : 'Register!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MAIN DASHBOARD (5 TABS) ====================
class MainDashboard extends StatefulWidget {
  final String displayName;
  final String username;
  final Uint8List? profileImage;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final Future<void> Function() onPickProfilePhoto;
  final VoidCallback onLogout;
  final Function(String newName) onProfileChanged;
  final VoidCallback onDeleteAccount;

  const MainDashboard({
    super.key,
    required this.displayName,
    required this.username,
    required this.profileImage,
    required this.language,
    required this.onLanguageChanged,
    required this.onPickProfilePhoto,
    required this.onLogout,
    required this.onProfileChanged,
    required this.onDeleteAccount,
  });

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  final List<TransitTrip> _trips = [];

  void _goToTab(int index) => setState(() => _currentIndex = index);

  bool get _isIndonesian => widget.language == 'Bahasa Indonesia';

  void _setLanguage(String language) => widget.onLanguageChanged(language);

  double get _totalCarbonSavedGrams =>
      _trips.fold(0, (total, trip) => total + trip.carbonSavedGrams);

  int get _totalCostSaved =>
      _trips.fold(0, (total, trip) => total + trip.costSaved);

  void _saveTrip(TransitTrip trip) {
    setState(() => _trips.insert(0, trip));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isIndonesian
              ? '${_tr(trip.title, true)} berhasil dicatat di Aktivitas.'
              : '${_tr(trip.title, false)} was added to Activity.',
        ),
      ),
    );
  }

  void _showQuickEntry(String type) {
    var distanceInput = '';
    var originInput = '';
    var destinationInput = '';
    final isPrivateRoute = type == 'Rute Pribadi';
    final isFlight = type == 'Flight';
    var vehicleType = 'Mobil';
    const emissionRates = <String, double>{'Mobil': 192, 'Motor': 103};
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final distance = double.tryParse(
            distanceInput.trim().replaceAll(',', '.'),
          );
          final emissionRate = isFlight ? 255.0 : emissionRates[vehicleType]!;
          final emittedGrams =
              distance != null &&
                  distance.isFinite &&
                  distance > 0 &&
                  distance <= 20000
              ? distance * emissionRate
              : 0.0;
          final title = isPrivateRoute
              ? (_isIndonesian ? 'Catat rute pribadi' : 'Record private route')
              : isFlight
              ? (_isIndonesian ? 'Catat penerbangan' : 'Record a flight')
              : (_isIndonesian
                    ? 'Catat perjalanan manual'
                    : 'Manual trip entry');

          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPrivateRoute || !isFlight) ...[
                    DropdownButtonFormField<String>(
                      initialValue: vehicleType,
                      decoration: InputDecoration(
                        labelText: _isIndonesian
                            ? 'Jenis kendaraan'
                            : 'Vehicle type',
                      ),
                      items: emissionRates.keys
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(
                                mode == 'Mobil'
                                    ? (_isIndonesian ? 'Mobil' : 'Car')
                                    : (_isIndonesian ? 'Motor' : 'Motorcycle'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => vehicleType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _isIndonesian ? 'Titik asal' : 'Origin',
                      hintText: _isIndonesian ? 'Contoh: Depok' : 'e.g. Depok',
                    ),
                    onChanged: (value) => originInput = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _isIndonesian ? 'Tujuan' : 'Destination',
                      hintText: _isIndonesian
                          ? 'Contoh: Sudirman'
                          : 'e.g. Sudirman',
                    ),
                    onChanged: (value) => destinationInput = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _isIndonesian ? 'Jarak (km)' : 'Distance (km)',
                      hintText: _isIndonesian ? 'Contoh: 18.5' : 'e.g. 18.5',
                    ),
                    onChanged: (value) {
                      distanceInput = value;
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.mintLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_isIndonesian ? 'Estimasi emisi CO₂' : 'Estimated CO₂ emissions'}: '
                      '${(emittedGrams / 1000).toStringAsFixed(2)} kg'
                      '${isFlight ? ' · 255 g/km' : ' · ${emissionRate.toStringAsFixed(0)} g/km'}',
                      style: const TextStyle(
                        color: AppColors.deepTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isIndonesian
                        ? 'Estimasi edukatif berdasarkan jarak dan faktor emisi rata-rata.'
                        : 'An educational estimate based on distance and average emission factors.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_isIndonesian ? 'Batal' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final parsedDistance = double.tryParse(
                    distanceInput.trim().replaceAll(',', '.'),
                  );
                  final origin = originInput.trim();
                  final destination = destinationInput.trim();
                  if (parsedDistance == null ||
                      !parsedDistance.isFinite ||
                      parsedDistance <= 0 ||
                      parsedDistance > 20000 ||
                      origin.isEmpty ||
                      destination.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isIndonesian
                              ? 'Isi lokasi dan jarak antara 0 sampai 20.000 km.'
                              : 'Enter both locations and a distance from 0 to 20,000 km.',
                        ),
                      ),
                    );
                    return;
                  }
                  final savedTitle = isFlight
                      ? 'Flight'
                      : isPrivateRoute
                      ? vehicleType
                      : 'Manual Entry';
                  Navigator.pop(dialogContext);
                  _saveTrip(
                    TransitTrip(
                      title: savedTitle,
                      route: '$origin → $destination',
                      distanceKm: parsedDistance,
                      carbonSavedGrams: 0,
                      carbonEmittedGrams: parsedDistance * emissionRate,
                      costSaved: 0,
                      date: DateTime.now(),
                      icon: isFlight
                          ? Icons.flight_takeoff_rounded
                          : isPrivateRoute
                          ? (vehicleType == 'Mobil'
                                ? Icons.directions_car_rounded
                                : Icons.motorcycle_rounded)
                          : Icons.edit_note_rounded,
                    ),
                  );
                },
                child: Text(_isIndonesian ? 'Simpan perjalanan' : 'Save trip'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      HomeTab(
        displayName: widget.displayName,
        profileImage: widget.profileImage,
        isIndonesian: _isIndonesian,
        carbonSavedGrams: _totalCarbonSavedGrams,
        costSaved: _totalCostSaved,
        onNavigate: _goToTab,
        onQuickAction: (label) {
          if (label == 'Rute Pribadi' ||
              label == 'Flight' ||
              label == 'Manual Entry') {
            _showQuickEntry(label);
          } else if (label == 'News feed' || label == 'Article') {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$label dibuka.')));
          }
        },
      ),
      FootprintTab(
        trips: _trips,
        isIndonesian: _isIndonesian,
        totalCarbonSavedGrams: _totalCarbonSavedGrams,
        totalCostSaved: _totalCostSaved,
        onSaveTrip: _saveTrip,
      ),
      OffsetTab(isIndonesian: _isIndonesian),
      ActivityTab(trips: _trips, isIndonesian: _isIndonesian),
      AccountTab(
        displayName: widget.displayName,
        username: widget.username,
        profileImage: widget.profileImage,
        isIndonesian: _isIndonesian,
        onLanguageChanged: _setLanguage,
        onPickProfilePhoto: widget.onPickProfilePhoto,
        onLogout: widget.onLogout,
        onProfileChanged: widget.onProfileChanged,
        onDeleteAccount: widget.onDeleteAccount,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mintLight,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: _isIndonesian ? 'Beranda' : 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco_rounded),
            label: _isIndonesian ? 'Perjalanan' : 'Journey',
          ),
          NavigationDestination(
            icon: Icon(Icons.forest_outlined),
            selectedIcon: Icon(Icons.forest_rounded),
            label: _isIndonesian ? 'Kalkulasi' : 'Offset',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus_rounded),
            label: _isIndonesian ? 'Aktivitas' : 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: _isIndonesian ? 'Akun' : 'Account',
          ),
        ],
      ),
    );
  }
}

class TransitTrip {
  final String title;
  final String route;
  final double distanceKm;
  final double carbonSavedGrams;
  final double carbonEmittedGrams;
  final int costSaved;
  final DateTime date;
  final IconData icon;

  const TransitTrip({
    required this.title,
    required this.route,
    required this.distanceKm,
    required this.carbonSavedGrams,
    this.carbonEmittedGrams = 0,
    required this.costSaved,
    required this.date,
    required this.icon,
  });
}

class ProfileAvatar extends StatelessWidget {
  final Uint8List? imageBytes;
  final double radius;
  final Color backgroundColor;

  const ProfileAvatar({
    super.key,
    required this.imageBytes,
    required this.radius,
    this.backgroundColor = AppColors.mintLight,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: imageBytes == null
          ? Icon(
              Icons.person_rounded,
              size: radius * 1.05,
              color: AppColors.deepTeal,
            )
          : ClipOval(
              child: Image.memory(
                imageBytes!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  size: radius * 1.05,
                  color: AppColors.deepTeal,
                ),
              ),
            ),
    );
  }
}

String _formatNumber(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}

String _tr(String text, bool isIndonesian) {
  if (!isIndonesian) {
    const englishTranslations = <String, String>{
      'Rute Pribadi': 'Private Route',
      'Mobil': 'Car',
      'Motor': 'Motorcycle',
      'Sepeda': 'Bicycle',
      'Tutup': 'Close',
      'Rencanakan rute': 'Plan a route',
      'Pilih stasiun/halte atau simulasikan lokasi perjalanan Jabodetabek.':
          'Choose stations/stops or simulate a Jabodetabek route.',
      'Moda transportasi': 'Transport mode',
      'Halte Asal': 'Origin bus stop',
      'Stasiun Asal': 'Origin station',
      'Halte Tujuan': 'Destination bus stop',
      'Stasiun Tujuan': 'Destination station',
      'Titik Asal / Lokasi Penjemputan': 'Origin / Pickup Location',
      'Contoh: Cikarang': 'e.g. Cikarang',
      'Tujuan Akhir di Jabodetabek': 'Destination in Jabodetabek',
      'Contoh: Grand Indonesia, Monas, Sudirman':
          'e.g. Grand Indonesia, Monas, Sudirman',
      'Jarak perjalanan': 'Trip distance',
      'CO₂ ditekan dibanding mobil': 'CO₂ avoided vs. car',
      'Estimasi emisi moda terpilih': 'Estimated mode emissions',
      'Estimasi biaya dihemat': 'Estimated cost saved',
      'Estimasi tarif': 'Estimated fare',
      'Estimasi biaya perjalanan': 'Estimated trip cost',
      'Simpan Perjalanan / Catat Rute': 'Save Trip / Record Route',
    };
    return englishTranslations[text] ?? text;
  }
  const translations = <String, String>{
    'Welcome aboard! Record your activity to begin neutralising your footprint': 'Selamat datang! Catat perjalanan untuk mulai mengurangi jejak karbon Anda.',
    'Ready to track? Tap to track your carbon footprint':
        'Siap melacak? Ketuk untuk memantau jejak karbon Anda',
    'Your Transitify Impact': 'Dampak Transitify Anda',
    'CO₂ Saved': 'CO₂ Dihemat',
    'Cost Saved': 'Biaya Dihemat',
    'Quick Actions': 'Aksi Cepat',
    'Rute Pribadi': 'Rute Pribadi',
    'Flight': 'Penerbangan',
    'Manual': 'Manual',
    'Board': 'Peringkat',
    'Feeds & Updates': 'Berita & Informasi',
    'See all': 'Lihat semua',
    'Top Carbon Savers': 'Penghemat Karbon Teratas',
    'Apa Itu Jejak Karbon dan Kenapa Harus Peduli?':
        'Apa Itu Jejak Karbon dan Kenapa Harus Peduli?',
    '15.4 kg CO₂ saved': '15.4 kg CO₂ dihemat',
    '12.8 kg CO₂ saved': '12.8 kg CO₂ dihemat',
    '10.2 kg CO₂ saved': '10.2 kg CO₂ dihemat',
    'Tutup': 'Tutup',
    'Rencanakan rute': 'Rencanakan rute',
    'Journey & Transit Planner': 'Perencana Rute & Transit',
    'Pilih stasiun/halte atau simulasikan lokasi perjalanan Jabodetabek.':
        'Pilih stasiun/halte atau simulasikan lokasi perjalanan Jabodetabek.',
    'Moda transportasi': 'Moda transportasi',
    'Halte Asal': 'Halte Asal',
    'Stasiun Asal': 'Stasiun Asal',
    'Halte Tujuan': 'Halte Tujuan',
    'Stasiun Tujuan': 'Stasiun Tujuan',
    'Titik Asal / Lokasi Penjemputan': 'Titik Asal / Lokasi Penjemputan',
    'Tujuan Akhir di Jabodetabek': 'Tujuan Akhir di Jabodetabek',
    'Contoh: Cikarang': 'Contoh: Cikarang',
    'Contoh: Grand Indonesia, Monas, Sudirman':
        'Contoh: Grand Indonesia, Monas, Sudirman',
    'Cari Rute & Hitung Dampak': 'Cari Rute & Hitung Dampak',
    'Jarak perjalanan': 'Jarak perjalanan',
    'CO₂ ditekan dibanding mobil': 'CO₂ ditekan dibanding mobil',
    'Estimasi emisi moda terpilih': 'Estimasi emisi moda terpilih',
    'Estimasi biaya dihemat': 'Estimasi biaya dihemat',
    'Simpan Perjalanan / Catat Rute': 'Simpan Perjalanan / Catat Rute',
    'Selamatkan Hutan Gambut Kampar': 'Selamatkan Hutan Gambut Kampar',
    'Pulihkan Pesisir Bali': 'Pulihkan Pesisir Bali',
    'Desa Bakau Asri': 'Desa Bakau Asri',
    'Hijaukan Pesisir Sumatera': 'Hijaukan Pesisir Sumatera',
    'Dukung proyek lingkungan': 'Dukung proyek lingkungan',
    'Nominal demo': 'Nominal demo',
    'Konfirmasi': 'Konfirmasi',
    'DONASI PENANAMAN POHON / NETRALKAN KARBON':
        'DONASI PENANAMAN POHON / NETRALKAN KARBON',
    'Activity': 'Aktivitas',
    'All Types': 'Semua Jenis',
    'Results': 'Hasil',
    'KRL Commuter Line': 'KRL Commuter Line',
    'TransJakarta / BRT': 'TransJakarta / BRT',
    'MRT Jakarta': 'MRT Jakarta',
    'Sepeda': 'Sepeda',
    'Motor': 'Motor',
    'Mobil': 'Mobil',
    'Ojol / Ride-hailing': 'Ojol / Transportasi daring',
    'Manual Entry': 'Input Manual',
    'Groups': 'Grup',
    'Create New Group': 'Buat Grup Baru',
    'Join with Invite Code': 'Gabung dengan Kode Undangan',
    'Your Groups': 'Grup Anda',
    '2 groups joined': 'Bergabung dengan 2 grup',
    'General Settings': 'Pengaturan Umum',
    'Edit Profile': 'Edit Profil',
    'Change Profile Picture': 'Ubah Foto Profil',
    'Sync Master Data': 'Sinkronkan Data Utama',
    'Active Tracking Session': 'Sesi Pelacakan Aktif',
    'No active session': 'Tidak ada sesi aktif',
    'Payment Methods': 'Metode Pembayaran',
    'Saved Routes': 'Rute Tersimpan',
    'Switch Language': 'Ganti Bahasa',
    'Logout': 'Keluar',
    'Delete Account': 'Hapus Akun',
    'Delete Account?': 'Hapus Akun?',
    'This action is permanent. All your Transitify carbon history will be erased.': 'Tindakan ini permanen. Semua riwayat karbon Transitify Anda akan dihapus.',
    'Cancel': 'Batal',
    'Delete account': 'Hapus akun',
    'Full Name': 'Nama Lengkap',
    'Save': 'Simpan',
    'COMING SOON': 'SEGERA HADIR',
    'Dihemat': 'Dihemat',
    'Estimasi biaya': 'Estimasi biaya',
    'Cari Rute': 'Cari Rute',
    'Donasi berhasil dicatat. Terima kasih!':
        'Donasi berhasil dicatat. Terima kasih!',
    'Language switched to Bahasa Indonesia.':
        'Bahasa diubah ke Bahasa Indonesia.',
    'Language switched to English.': 'Language switched to English.',
    'All Types trips': 'Semua perjalanan',
    'No activity for this category.': 'Tidak ada aktivitas untuk kategori ini.',
    'No trips yet. Save a route from Journey & Transit Planner.':
        'Belum ada perjalanan. Simpan rute dari Perencana Rute & Transit.',
  };
  return translations[text] ?? text;
}

// ==================== TAB 1: HOME ====================
class HomeTab extends StatelessWidget {
  final String displayName;
  final Uint8List? profileImage;
  final bool isIndonesian;
  final double carbonSavedGrams;
  final int costSaved;
  final Function(int tabIndex) onNavigate;
  final Function(String label) onQuickAction;

  const HomeTab({
    super.key,
    required this.displayName,
    required this.profileImage,
    required this.isIndonesian,
    required this.carbonSavedGrams,
    required this.costSaved,
    required this.onNavigate,
    required this.onQuickAction,
  });

  static const String _forestImage =
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=1200&q=80';
  static const String _bundaranImage =
      'https://images.unsplash.com/photo-1555899434-94d1368aa7af?auto=format&fit=crop&w=1200&q=80';

  Widget _netImage(String url, {BoxFit fit = BoxFit.cover}) {
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.deepTeal,
        child: const Center(
          child: Icon(Icons.nature_rounded, color: Colors.white54, size: 48),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.mintLight,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  void _showArticle(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isIndonesian
              ? 'Apa Itu Jejak Karbon dan Kenapa Harus Peduli?'
              : 'What Is a Carbon Footprint and Why Should We Care?',
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: SingleChildScrollView(
            child: Text(
              isIndonesian
                  ? 'Pernahkah Anda merasa langit Jakarta dan sekitarnya sering kali diselimuti kabut abu-abu tebal? Salah satu penyebab utamanya adalah polusi emisi knalpot dari jutaan kendaraan pribadi di jalanan Jabodetabek.\n\n'
                        'Apa Itu Jejak Karbon?\n'
                        'Jejak karbon adalah total emisi gas rumah kaca (seperti CO₂) yang dihasilkan dari aktivitas harian kita, terutama saat berkendara menggunakan kendaraan pribadi.\n\n'
                        'Mengapa Kita Harus Peduli?\n'
                        'Polusi udara berdampak langsung pada kesehatan paru-paru, kualitas hidup, dan lingkungan di sekitar kita.\n\n'
                        'Solusi Sederhana Bersama Transitify:\n'
                        'Dengan beralih ke transportasi publik seperti KRL, TransJakarta, dan MRT, kita secara nyata mengurangi emisi karbon per penumpang hingga lebih dari 70%. Transitify membantu Anda memantau estimasi emisi CO₂ yang berhasil dihemat serta biaya yang ditabung setiap kali memilih perjalanan ramah lingkungan.\n\n'
                        'Mari berkontribusi menjaga udara Jabodetabek tetap bersih!'
                  : 'Have you noticed the thick gray haze that often covers the skies around Jakarta? One major cause is exhaust pollution from millions of private vehicles on Jabodetabek roads.\n\n'
                        'What Is a Carbon Footprint?\n'
                        'A carbon footprint is the total greenhouse gas emissions, such as CO₂, produced by our daily activities, especially when travelling in private vehicles.\n\n'
                        'Why Should We Care?\n'
                        'Air pollution directly affects lung health, quality of life, and the environment around us.\n\n'
                        'A Simple Solution with Transitify:\n'
                        'By switching to public transport such as KRL, TransJakarta, and MRT, we can reduce per-passenger carbon emissions by more than 70%. Transitify helps you track estimated CO₂ emissions avoided and money saved every time you choose a greener trip.\n\n'
                        'Let’s help keep Jabodetabek’s air clean!',
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('Tutup', isIndonesian)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onNavigate(1);
            },
            child: Text(_tr('Rencanakan rute', isIndonesian)),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr('Top Carbon Savers', isIndonesian)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LeaderRow(
              rank: 1,
              handle: '@Nur Alam Fajar Abdullah',
              value: _tr('15.4 kg CO₂ saved', isIndonesian),
              medal: Colors.amber,
            ),
            _LeaderRow(
              rank: 2,
              handle: '@Abdul Alif Muthalif Muis',
              value: _tr('12.8 kg CO₂ saved', isIndonesian),
              medal: Colors.grey,
            ),
            _LeaderRow(
              rank: 3,
              handle: '@Fadil Imamsyah',
              value: _tr('10.2 kg CO₂ saved', isIndonesian),
              medal: Colors.brown,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('Tutup', isIndonesian)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header: dark forest banner
          Stack(
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: _netImage(_forestImage),
              ),
              Container(
                height: 210,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Row(
                  children: [
                    ProfileAvatar(
                      imageBytes: profileImage,
                      radius: 25,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isIndonesian ? 'Halo' : 'Hi'} $displayName,',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _tr(
                              'Welcome aboard! Record your activity to begin neutralising your footprint',
                              isIndonesian,
                            ),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 20,
                top: 18,
                child: Icon(Icons.eco_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Interactive banner card
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onNavigate(1),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.ecoGreen, AppColors.deepTeal],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.spa_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _tr(
                              'Ready to track? Tap to track your carbon footprint',
                              isIndonesian,
                            ),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Eco-metrics card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('Your Transitify Impact', isIndonesian),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.deepTeal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.cloud_off_rounded,
                              value:
                                  '${(carbonSavedGrams / 1000).toStringAsFixed(2)} kg',
                              label: _tr('CO₂ Saved', isIndonesian),
                              color: AppColors.ecoGreen,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.savings_outlined,
                              value: 'Rp ${_formatNumber(costSaved)}',
                              label: _tr('Cost Saved', isIndonesian),
                              color: AppColors.deepTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick actions grid
                Text(
                  _tr('Quick Actions', isIndonesian),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _QuickAction(
                      icon: Icons.directions_car_rounded,
                      label: _tr('Rute Pribadi', isIndonesian),
                      color: Colors.blue,
                      onTap: () => onQuickAction('Rute Pribadi'),
                    ),
                    _QuickAction(
                      icon: Icons.flight_takeoff_rounded,
                      label: _tr('Flight', isIndonesian),
                      color: Colors.purple,
                      onTap: () => onQuickAction('Flight'),
                    ),
                    _QuickAction(
                      icon: Icons.edit_note_rounded,
                      label: _tr('Manual', isIndonesian),
                      color: Colors.orange,
                      onTap: () => onQuickAction('Manual Entry'),
                    ),
                    _QuickAction(
                      icon: Icons.emoji_events_rounded,
                      label: _tr('Board', isIndonesian),
                      color: AppColors.ecoGreen,
                      onTap: () => _showLeaderboard(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Feeds & Updates
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tr('Feeds & Updates', isIndonesian),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showArticle(context),
                      child: Text(_tr('See all', isIndonesian)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    onTap: () => _showArticle(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: _netImage(_bundaranImage),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isIndonesian
                                    ? 'Apa Itu Jejak Karbon dan Kenapa Harus Peduli?'
                                    : 'What Is a Carbon Footprint and Why Should We Care?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'by Nur Alam Fajar Abdullah',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Top carbon savers
                Text(
                  _tr('Top Carbon Savers', isIndonesian),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _LeaderRow(
                  rank: 1,
                  handle: '@Nur Alam Fajar Abdullah',
                  value: _tr('15.4 kg CO₂ saved', isIndonesian),
                  medal: Colors.amber,
                ),
                _LeaderRow(
                  rank: 2,
                  handle: '@Abdul Alif Muthalif Muis',
                  value: _tr('12.8 kg CO₂ saved', isIndonesian),
                  medal: Colors.grey,
                ),
                _LeaderRow(
                  rank: 3,
                  handle: '@Fadil Imamsyah',
                  value: _tr('10.2 kg CO₂ saved', isIndonesian),
                  medal: Colors.brown,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final String handle;
  final String value;
  final Color medal;
  const _LeaderRow({
    required this.rank,
    required this.handle,
    required this.value,
    required this.medal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.softGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medal,
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          handle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.deepTeal,
          ),
        ),
      ),
    );
  }
}

// ==================== TAB 2: FOOTPRINT ====================
class TransitMode {
  final String name;
  final IconData icon;
  final double emissionsGramsPerKm;

  const TransitMode(this.name, this.icon, this.emissionsGramsPerKm);

  bool get isPublic => this == _krlMode || this == _mrtMode || this == _busMode;
}

class TransitStop {
  final String name;
  final String corridor;
  final double latitude;
  final double longitude;

  const TransitStop(this.name, this.corridor, this.latitude, this.longitude);

  String get label => '$name · $corridor';
}

const _krlMode = TransitMode('KRL Commuter Line', Icons.train_rounded, 35);
const _mrtMode = TransitMode('MRT Jakarta', Icons.subway_rounded, 40);
const _busMode = TransitMode(
  'TransJakarta / BRT',
  Icons.directions_bus_rounded,
  80,
);
const _bikeMode = TransitMode('Sepeda', Icons.directions_bike_rounded, 0);
const _motorMode = TransitMode('Motor', Icons.two_wheeler_rounded, 103);
const _carMode = TransitMode('Mobil', Icons.directions_car_rounded, 192);
const _ojolMode = TransitMode(
  'Ojol / Ride-hailing',
  Icons.electric_rickshaw_rounded,
  105,
);
const _transitModes = [
  _krlMode,
  _mrtMode,
  _busMode,
  _bikeMode,
  _motorMode,
  _carMode,
  _ojolMode,
];

const List<TransitStop> _krlStops = [
  TransitStop('Cikarang', 'Lin Cikarang', -6.236, 107.156),
  TransitStop('Lemahabang', 'Lin Cikarang', -6.267, 107.176),
  TransitStop('Kedunggedeh', 'Lin Cikarang', -6.301, 107.207),
  TransitStop('Cibitung', 'Lin Cikarang', -6.260, 107.101),
  TransitStop('Tambun', 'Lin Cikarang', -6.262, 107.055),
  TransitStop('Bekasi Timur', 'Lin Cikarang', -6.249, 107.017),
  TransitStop('Bekasi', 'Lin Cikarang', -6.236, 106.999),
  TransitStop('Kranji', 'Lin Cikarang', -6.224, 106.973),
  TransitStop('Cakung', 'Lin Cikarang', -6.220, 106.949),
  TransitStop('Klender Baru', 'Lin Cikarang', -6.214, 106.929),
  TransitStop('Buaran', 'Lin Cikarang', -6.213, 106.916),
  TransitStop('Klender', 'Lin Cikarang', -6.214, 106.900),
  TransitStop('Jatinegara', 'Lin Cikarang', -6.216, 106.870),
  TransitStop('Matraman', 'Lin Cikarang', -6.205, 106.858),
  TransitStop('Manggarai', 'Lin Cikarang', -6.209, 106.850),
  TransitStop('Sudirman', 'Lin Cikarang', -6.201, 106.823),
  TransitStop('Karet', 'Lin Cikarang', -6.204, 106.817),
  TransitStop('Tanah Abang', 'Lin Cikarang', -6.186, 106.810),
  TransitStop('Duri', 'Lin Cikarang', -6.153, 106.807),
  TransitStop('Angke', 'Lin Cikarang', -6.143, 106.800),
  TransitStop('Kampung Bandan', 'Lin Cikarang', -6.128, 106.800),
  TransitStop('Jakarta Kota', 'Lin Cikarang', -6.137, 106.814),
  TransitStop('Bogor', 'Lin Bogor', -6.595, 106.790),
  TransitStop('Cilebut', 'Lin Bogor', -6.515, 106.800),
  TransitStop('Bojong Gede', 'Lin Bogor', -6.481, 106.800),
  TransitStop('Citayam', 'Lin Bogor', -6.448, 106.800),
  TransitStop('Depok', 'Lin Bogor', -6.404, 106.821),
  TransitStop('Depok Baru', 'Lin Bogor', -6.392, 106.823),
  TransitStop('Pondok Cina', 'Lin Bogor', -6.372, 106.832),
  TransitStop('Universitas Indonesia', 'Lin Bogor', -6.361, 106.831),
  TransitStop('Universitas Pancasila', 'Lin Bogor', -6.338, 106.834),
  TransitStop('Lenteng Agung', 'Lin Bogor', -6.330, 106.834),
  TransitStop('Tanjung Barat', 'Lin Bogor', -6.309, 106.838),
  TransitStop('Pasar Minggu', 'Lin Bogor', -6.285, 106.844),
  TransitStop('Pasar Minggu Baru', 'Lin Bogor', -6.277, 106.850),
  TransitStop('Duren Kalibata', 'Lin Bogor', -6.257, 106.858),
  TransitStop('Cawang', 'Lin Bogor', -6.243, 106.858),
  TransitStop('Tebet', 'Lin Bogor', -6.226, 106.858),
  TransitStop('Manggarai', 'Lin Bogor', -6.209, 106.850),
  TransitStop('Sudirman', 'Lin Bogor', -6.201, 106.823),
  TransitStop('Tanah Abang', 'Lin Rangkasbitung', -6.186, 106.810),
  TransitStop('Palmerah', 'Lin Rangkasbitung', -6.207, 106.797),
  TransitStop('Kebayoran', 'Lin Rangkasbitung', -6.237, 106.782),
  TransitStop('Pondok Ranji', 'Lin Rangkasbitung', -6.276, 106.744),
  TransitStop('Jurangmangu', 'Lin Rangkasbitung', -6.288, 106.729),
  TransitStop('Sudimara', 'Lin Rangkasbitung', -6.296, 106.710),
  TransitStop('Rawabuntu', 'Lin Rangkasbitung', -6.301, 106.683),
  TransitStop('Serpong', 'Lin Rangkasbitung', -6.320, 106.665),
  TransitStop('Cisauk', 'Lin Rangkasbitung', -6.324, 106.641),
  TransitStop('Cicayur', 'Lin Rangkasbitung', -6.333, 106.619),
  TransitStop('Parung Panjang', 'Lin Rangkasbitung', -6.344, 106.570),
  TransitStop('Maja', 'Lin Rangkasbitung', -6.337, 106.455),
  TransitStop('Rangkasbitung', 'Lin Rangkasbitung', -6.358, 106.251),
  TransitStop('Duri', 'Lin Tangerang', -6.153, 106.807),
  TransitStop('Grogol', 'Lin Tangerang', -6.166, 106.789),
  TransitStop('Pesing', 'Lin Tangerang', -6.163, 106.774),
  TransitStop('Taman Kota', 'Lin Tangerang', -6.158, 106.761),
  TransitStop('Rawa Buaya', 'Lin Tangerang', -6.167, 106.733),
  TransitStop('Bojong Indah', 'Lin Tangerang', -6.163, 106.719),
  TransitStop('Kalideres', 'Lin Tangerang', -6.151, 106.702),
  TransitStop('Poris', 'Lin Tangerang', -6.166, 106.675),
  TransitStop('Batu Ceper', 'Lin Tangerang', -6.166, 106.660),
  TransitStop('Tangerang', 'Lin Tangerang', -6.178, 106.632),
  TransitStop('Jakarta Kota', 'Lin Tanjung Priok', -6.137, 106.814),
  TransitStop('Kampung Bandan', 'Lin Tanjung Priok', -6.128, 106.800),
  TransitStop('Ancol', 'Lin Tanjung Priok', -6.125, 106.835),
  TransitStop('Tanjung Priok', 'Lin Tanjung Priok', -6.108, 106.880),
];

const List<TransitStop> _mrtStops = [
  TransitStop('Lebak Bulus Grab', 'MRT Fase 1', -6.289, 106.774),
  TransitStop('Fatmawati Indomaret', 'MRT Fase 1', -6.292, 106.797),
  TransitStop('Cipete Raya', 'MRT Fase 1', -6.278, 106.797),
  TransitStop('Haji Nawi', 'MRT Fase 1', -6.267, 106.797),
  TransitStop('Blok A', 'MRT Fase 1', -6.256, 106.798),
  TransitStop('Blok M BCA', 'MRT Fase 1', -6.244, 106.799),
  TransitStop('ASEAN', 'MRT Fase 1', -6.238, 106.799),
  TransitStop('Senayan Mastercard', 'MRT Fase 1', -6.226, 106.802),
  TransitStop('Istora Mandiri', 'MRT Fase 1', -6.223, 106.809),
  TransitStop('Bendungan Hilir', 'MRT Fase 1', -6.215, 106.816),
  TransitStop('Setiabudi Astra', 'MRT Fase 1', -6.208, 106.819),
  TransitStop('Dukuh Atas BNI', 'MRT Fase 1', -6.200, 106.823),
  TransitStop('Bundaran HI Bank DKI', 'MRT Fase 1', -6.193, 106.823),
  TransitStop('Thamrin', 'MRT Fase 2A (rencana)', -6.190, 106.823),
  TransitStop('Monas', 'MRT Fase 2A (rencana)', -6.176, 106.823),
  TransitStop('Harmoni', 'MRT Fase 2A (rencana)', -6.166, 106.823),
  TransitStop('Sawah Besar', 'MRT Fase 2A (rencana)', -6.160, 106.823),
  TransitStop('Mangga Besar', 'MRT Fase 2A (rencana)', -6.151, 106.823),
  TransitStop('Glodok', 'MRT Fase 2A (rencana)', -6.143, 106.820),
  TransitStop('Kota', 'MRT Fase 2A (rencana)', -6.137, 106.814),
];

const List<TransitStop> _busStops = [
  TransitStop('Blok M', 'Koridor 1', -6.244, 106.799),
  TransitStop('Bundaran HI', 'Koridor 1', -6.193, 106.823),
  TransitStop('Harmoni', 'Koridor 1 / 3', -6.166, 106.823),
  TransitStop('Kota', 'Koridor 1', -6.137, 106.814),
  TransitStop('Pluit', 'Koridor 9', -6.124, 106.790),
  TransitStop('Pinang Ranti', 'Koridor 9', -6.291, 106.906),
  TransitStop('Kalideres', 'Koridor 3', -6.151, 106.702),
  TransitStop('Pasar Baru', 'Koridor 3', -6.162, 106.835),
  TransitStop('Ragunan', 'Koridor 6', -6.309, 106.820),
  TransitStop('Dukuh Atas', 'Koridor 6', -6.200, 106.823),
  TransitStop('Kampung Melayu', 'Koridor 5', -6.225, 106.866),
  TransitStop('Ancol', 'Koridor 5', -6.125, 106.835),
  TransitStop('Pulogadung', 'Koridor 2', -6.183, 106.900),
  TransitStop('Monas', 'Koridor 2', -6.176, 106.823),
  TransitStop('Ciledug', 'Koridor 13', -6.237, 106.706),
  TransitStop('Tegal Mampang', 'Koridor 13', -6.240, 106.825),
  TransitStop('BSD', 'TransJabodetabek', -6.302, 106.665),
  TransitStop('Alam Sutera', 'TransJabodetabek', -6.241, 106.652),
  TransitStop('Cikarang', 'TransJabodetabek', -6.236, 107.156),
  TransitStop('Bekasi', 'TransJabodetabek', -6.236, 106.999),
  TransitStop('Depok', 'TransJabodetabek', -6.404, 106.821),
  TransitStop('Bogor', 'TransJabodetabek', -6.595, 106.790),
];

List<TransitStop> _stopsFor(TransitMode mode) {
  if (mode == _krlMode) return _krlStops;
  if (mode == _mrtMode) return _mrtStops;
  if (mode == _busMode) return _busStops;
  return const [];
}

double _distanceBetweenKm(
  double latitude1,
  double longitude1,
  double latitude2,
  double longitude2,
) {
  const earthRadiusKm = 6371.0;
  final latitudeDelta = _radians(latitude2 - latitude1);
  final longitudeDelta = _radians(longitude2 - longitude1);
  final haversine =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(_radians(latitude1)) *
          math.cos(_radians(latitude2)) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  return earthRadiusKm *
      2 *
      math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
}

double _radians(double degrees) => degrees * math.pi / 180;

const List<({List<String> aliases, double latitude, double longitude})>
_knownLocations = [
  (
    aliases: ['cikarang', 'stasiun cikarang'],
    latitude: -6.236,
    longitude: 107.156,
  ),
  (aliases: ['bekasi'], latitude: -6.236, longitude: 106.999),
  (aliases: ['depok'], latitude: -6.404, longitude: 106.821),
  (aliases: ['bogor'], latitude: -6.595, longitude: 106.790),
  (aliases: ['tangerang'], latitude: -6.178, longitude: 106.632),
  (aliases: ['bsd', 'serpong'], latitude: -6.302, longitude: 106.665),
  (aliases: ['ciledug'], latitude: -6.237, longitude: 106.706),
  (aliases: ['rawa buaya'], latitude: -6.167, longitude: 106.733),
  (
    aliases: ['sudirman', 'sudirman station'],
    latitude: -6.201,
    longitude: 106.823,
  ),
  (
    aliases: ['grand indonesia', 'bundaran hi', 'bundaran hotel indonesia'],
    latitude: -6.193,
    longitude: 106.823,
  ),
  (
    aliases: ['monas', 'monumen nasional'],
    latitude: -6.176,
    longitude: 106.823,
  ),
  (aliases: ['blok m'], latitude: -6.244, longitude: 106.799),
  (aliases: ['kota tua', 'jakarta kota'], latitude: -6.137, longitude: 106.814),
  (aliases: ['lebak bulus'], latitude: -6.289, longitude: 106.774),
  (aliases: ['pinang ranti'], latitude: -6.291, longitude: 106.906),
  (aliases: ['pluit'], latitude: -6.124, longitude: 106.790),
  (aliases: ['kalideres'], latitude: -6.151, longitude: 106.702),
  (aliases: ['pasar baru'], latitude: -6.162, longitude: 106.835),
  (aliases: ['manggarai'], latitude: -6.209, longitude: 106.850),
  (aliases: ['tanah abang'], latitude: -6.186, longitude: 106.810),
  (
    aliases: ['rawamangun', 'pulo gadung', 'pulogadung'],
    latitude: -6.183,
    longitude: 106.900,
  ),
  (aliases: ['tanjung priok'], latitude: -6.108, longitude: 106.880),
  (aliases: ['harmony', 'harmoni'], latitude: -6.166, longitude: 106.823),
  (aliases: ['kebayoran'], latitude: -6.237, longitude: 106.782),
  (aliases: ['kuningan'], latitude: -6.229, longitude: 106.831),
  (aliases: ['senayan'], latitude: -6.226, longitude: 106.802),
  (aliases: ['cawang'], latitude: -6.243, longitude: 106.858),
  (aliases: ['bintaro'], latitude: -6.276, longitude: 106.744),
  (aliases: ['jatiasih'], latitude: -6.307, longitude: 106.971),
  (aliases: ['jatibening'], latitude: -6.259, longitude: 106.951),
  (aliases: ['cibubur'], latitude: -6.367, longitude: 106.883),
  (aliases: ['kelapa gading'], latitude: -6.160, longitude: 106.906),
  (aliases: ['pondok gede'], latitude: -6.286, longitude: 106.907),
];

({double latitude, double longitude})? _resolveLocation(String input) {
  final query = input.trim().toLowerCase();
  if (query.isEmpty) return null;
  final matchingAliases =
      _knownLocations
          .where((location) => location.aliases.any(query.contains))
          .toList()
        ..sort(
          (left, right) => right.aliases
              .where(query.contains)
              .fold<int>(
                0,
                (length, alias) =>
                    length > alias.length ? length : alias.length,
              )
              .compareTo(
                left.aliases
                    .where(query.contains)
                    .fold<int>(
                      0,
                      (length, alias) =>
                          length > alias.length ? length : alias.length,
                    ),
              ),
        );
  if (matchingAliases.isNotEmpty) {
    final location = matchingAliases.first;
    return (latitude: location.latitude, longitude: location.longitude);
  }
  final allStops = [..._krlStops, ..._mrtStops, ..._busStops];
  final matchingStops =
      allStops.where((stop) => query.contains(stop.name.toLowerCase())).toList()
        ..sort((left, right) => right.name.length.compareTo(left.name.length));
  if (matchingStops.isNotEmpty) {
    final stop = matchingStops.first;
    return (latitude: stop.latitude, longitude: stop.longitude);
  }
  return null;
}

int _estimateFare(TransitMode mode, double distanceKm) {
  if (mode == _krlMode) {
    final extraKm = math.max(0, distanceKm - 25);
    return 3000 + (extraKm / 10).ceil() * 1000;
  }
  if (mode == _mrtMode) {
    return (3000 + (distanceKm / 1.6).ceil() * 1000).clamp(3000, 14000).toInt();
  }
  if (mode == _busMode) return 3500;
  if (mode == _bikeMode) return 0;
  if (mode == _motorMode) return (distanceKm * 700).round();
  if (mode == _ojolMode) {
    return (distanceKm * 2800).ceil().clamp(8000, 200000).toInt();
  }
  return (distanceKm * 3000).round() + 10000;
}

class FootprintTab extends StatefulWidget {
  final List<TransitTrip> trips;
  final bool isIndonesian;
  final double totalCarbonSavedGrams;
  final int totalCostSaved;
  final ValueChanged<TransitTrip> onSaveTrip;

  const FootprintTab({
    super.key,
    required this.trips,
    required this.isIndonesian,
    required this.totalCarbonSavedGrams,
    required this.totalCostSaved,
    required this.onSaveTrip,
  });

  @override
  State<FootprintTab> createState() => _FootprintTabState();
}

class _FootprintTabState extends State<FootprintTab> {
  TransitMode _mode = _krlMode;
  TransitStop? _origin = _krlStops.first;
  TransitStop? _destination = _krlStops[20];
  final _originLocationController = TextEditingController();
  final _destinationLocationController = TextEditingController();
  double? _simulatedGpsDistanceKm;
  bool _gpsRouteCalculated = false;

  bool get _isGpsMode => !_mode.isPublic;

  double get _distanceKm {
    if (_isGpsMode) return _simulatedGpsDistanceKm ?? 0;
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) return 0;
    return _distanceBetweenKm(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        ) *
        (_mode == _mrtMode ? 1.12 : 1.3);
  }

  double get _carbonEmittedGrams => _mode.emissionsGramsPerKm * _distanceKm;

  double get _carbonSavedGrams =>
      (math.max(0, _carMode.emissionsGramsPerKm - _mode.emissionsGramsPerKm) *
              _distanceKm)
          .toDouble();

  int get _costSaved => _distanceKm <= 0
      ? 0
      : math
            .max(
              0,
              _estimateFare(_carMode, _distanceKm) -
                  _estimateFare(_mode, _distanceKm),
            )
            .toInt();

  int get _fare => _estimateFare(_mode, _distanceKm);

  bool get _routeReady {
    if (_distanceKm <= 0) return false;
    if (_isGpsMode) return _gpsRouteCalculated;
    return _origin != null &&
        _destination != null &&
        _origin!.name != _destination!.name;
  }

  void _selectMode(TransitMode? mode) {
    if (mode == null) return;
    setState(() {
      _mode = mode;
      _gpsRouteCalculated = false;
      _simulatedGpsDistanceKm = null;
      if (mode.isPublic) {
        final stops = _stopsFor(mode);
        _origin = stops.first;
        _destination = stops.length > 1 ? stops[1] : null;
      } else {
        _origin = null;
        _destination = null;
      }
    });
  }

  void _selectOrigin(TransitStop? stop) {
    if (stop == null) return;
    setState(() {
      _origin = stop;
      if (_destination?.name == stop.name) {
        _destination = _stopsFor(_mode)
            .firstWhere((candidate) => candidate.name != stop.name);
      }
    });
  }

  void _calculateGpsRoute() {
    final origin = _resolveLocation(_originLocationController.text);
    final destination = _resolveLocation(_destinationLocationController.text);
    if (origin == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isIndonesian
                ? 'Lokasi belum dikenali. Coba Cikarang, Depok, Rawa Buaya, Sudirman, Monas, atau Grand Indonesia.'
                : 'Location not recognized. Try Cikarang, Depok, Rawa Buaya, Sudirman, Monas, or Grand Indonesia.',
          ),
        ),
      );
      return;
    }
    final distance =
        _distanceBetweenKm(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        ) *
        1.3;
    if (distance < 0.1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isIndonesian
                ? 'Titik asal dan tujuan harus berbeda.'
                : 'Origin and destination must be different.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _simulatedGpsDistanceKm = distance;
      _gpsRouteCalculated = true;
    });
  }

  void _saveRoute() {
    if (!_routeReady) return;
    final title = _mode.name;
    final route = _isGpsMode
        ? '${_originLocationController.text.trim()} → ${_destinationLocationController.text.trim()}'
        : '${_origin!.name} → ${_destination!.name} · ${_origin!.corridor}';
    widget.onSaveTrip(
      TransitTrip(
        title: title,
        route: route,
        distanceKm: _distanceKm,
        carbonSavedGrams: _carbonSavedGrams,
        carbonEmittedGrams: _carbonEmittedGrams,
        costSaved: _costSaved,
        date: DateTime.now(),
        icon: _mode.icon,
      ),
    );
  }

  @override
  void dispose() {
    _originLocationController.dispose();
    _destinationLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stopsFor(_mode);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _tr('Journey & Transit Planner', widget.isIndonesian),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isIndonesian
                ? 'Pilih stasiun/halte atau simulasikan lokasi perjalanan Jabodetabek.'
                : 'Choose stations/stops or simulate a Jabodetabek route.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<TransitMode>(
            initialValue: _mode,
            decoration: InputDecoration(
              labelText: _tr('Moda transportasi', widget.isIndonesian),
              prefixIcon: Icon(Icons.commute_rounded),
            ),
            items: _transitModes
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Row(
                      children: [
                        Icon(mode.icon, color: AppColors.deepTeal, size: 20),
                        const SizedBox(width: 10),
                        Text(mode.name),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: _selectMode,
          ),
          const SizedBox(height: 16),
          if (_mode.isPublic) ...[
            DropdownButtonFormField<TransitStop>(
              initialValue: _origin,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _tr(
                  _mode == _busMode ? 'Halte Asal' : 'Stasiun Asal',
                  widget.isIndonesian,
                ),
                prefixIcon: const Icon(Icons.trip_origin_rounded),
              ),
              items: stops
                  .map(
                    (stop) => DropdownMenuItem(
                      value: stop,
                      child: Text(stop.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: _selectOrigin,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransitStop>(
              initialValue: _destination,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: _tr(
                  _mode == _busMode ? 'Halte Tujuan' : 'Stasiun Tujuan',
                  widget.isIndonesian,
                ),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              items: stops
                  .where((stop) => stop.name != _origin?.name)
                  .map(
                    (stop) => DropdownMenuItem(
                      value: stop,
                      child: Text(stop.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (stop) {
                if (stop != null) setState(() => _destination = stop);
              },
            ),
          ] else ...[
            TextField(
              controller: _originLocationController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.isIndonesian
                    ? 'Titik Asal / Lokasi Penjemputan'
                    : 'Origin / Pickup Location',
                hintText: widget.isIndonesian
                    ? 'Contoh: Cikarang'
                    : 'e.g. Cikarang',
                prefixIcon: const Icon(Icons.my_location_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Gunakan lokasi saat ini',
                  onPressed: () {
                    setState(() {
                      _originLocationController.text = 'Cikarang';
                      _gpsRouteCalculated = false;
                      _simulatedGpsDistanceKm = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Lokasi demo diisi Cikarang. GPS perangkat belum diaktifkan.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.gps_fixed_rounded),
                ),
              ),
              onChanged: (_) => setState(() {
                _gpsRouteCalculated = false;
                _simulatedGpsDistanceKm = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _destinationLocationController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.isIndonesian
                    ? 'Tujuan Akhir di Jabodetabek'
                    : 'Destination in Jabodetabek',
                hintText: widget.isIndonesian
                    ? 'Contoh: Grand Indonesia, Monas, Sudirman'
                    : 'e.g. Grand Indonesia, Monas, Sudirman',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: (_) => setState(() {
                _gpsRouteCalculated = false;
                _simulatedGpsDistanceKm = null;
              }),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _calculateGpsRoute,
              icon: const Icon(Icons.search_rounded),
              label: Text(
                _tr('Cari Rute & Hitung Dampak', widget.isIndonesian),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.mintLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _OffsetRow(
                  icon: Icons.straighten_rounded,
                  label: widget.isIndonesian
                      ? 'Jarak perjalanan'
                      : 'Trip distance',
                  value: '${_distanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(height: 14),
                _OffsetRow(
                  icon: Icons.cloud_off_rounded,
                  label: widget.isIndonesian
                      ? 'CO₂ ditekan dibanding mobil'
                      : 'CO₂ avoided vs. car',
                  value: '${(_carbonSavedGrams / 1000).toStringAsFixed(2)} kg',
                ),
                const SizedBox(height: 14),
                _OffsetRow(
                  icon: Icons.co2_rounded,
                  label: widget.isIndonesian
                      ? 'Estimasi emisi moda terpilih'
                      : 'Estimated mode emissions',
                  value:
                      '${(_carbonEmittedGrams / 1000).toStringAsFixed(2)} kg',
                ),
                const SizedBox(height: 14),
                _OffsetRow(
                  icon: Icons.payments_outlined,
                  label: widget.isIndonesian
                      ? 'Estimasi biaya dihemat'
                      : 'Estimated cost saved',
                  value: 'Rp ${_formatNumber(_costSaved)}',
                ),
                const SizedBox(height: 14),
                _OffsetRow(
                  icon: Icons.confirmation_number_outlined,
                  label: _mode.isPublic
                      ? (widget.isIndonesian
                            ? 'Estimasi tarif'
                            : 'Estimated fare')
                      : (widget.isIndonesian
                            ? 'Estimasi biaya perjalanan'
                            : 'Estimated trip cost'),
                  value: 'Rp ${_formatNumber(_fare)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _mode == _krlMode
                ? (widget.isIndonesian
                      ? 'Estimasi jarak garis rute + faktor lintasan. Tarif KRL mengikuti struktur Rp3.000 untuk 25 km pertama, lalu Rp1.000 tiap 10 km berikutnya. Nilai akhir dapat berbeda dari tarif resmi stasiun.'
                      : 'Estimated straight-line route distance plus route factor. KRL fare follows Rp3,000 for the first 25 km, then Rp1,000 for each additional 10 km. Actual station fares may vary.')
                : (widget.isIndonesian
                      ? 'Estimasi berbasis koordinat kota, bukan navigasi atau GPS langsung. Emisi dibanding mobil (192 g CO₂/km); tarif dan faktor emisi dapat berbeda di lapangan.'
                      : 'Estimated from city coordinates, not live navigation or GPS. Emissions are compared with a car (192 g CO₂/km); actual fares and emission factors may vary.'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _routeReady ? _saveRoute : null,
            icon: const Icon(Icons.add_road_rounded),
            label: Text(
              _tr('Simpan Perjalanan / Catat Rute', widget.isIndonesian),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.isIndonesian
                ? '${widget.trips.length} perjalanan tercatat · '
                      '${(widget.totalCarbonSavedGrams / 1000).toStringAsFixed(2)} kg CO₂ dihemat · '
                      'Rp ${_formatNumber(widget.totalCostSaved)}'
                : '${widget.trips.length} trips recorded · '
                      '${(widget.totalCarbonSavedGrams / 1000).toStringAsFixed(2)} kg CO₂ saved · '
                      'Rp ${_formatNumber(widget.totalCostSaved)}',
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OffsetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _OffsetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.deepTeal, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.deepTeal,
          ),
        ),
      ],
    );
  }
}

// ==================== TAB 3: OFFSET ====================
class OffsetProject {
  final String title;
  final String imageUrl;
  final String description;
  final String location;
  final double trees;
  const OffsetProject({
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.location,
    required this.trees,
  });
}

class OffsetTab extends StatelessWidget {
  final bool isIndonesian;

  const OffsetTab({super.key, required this.isIndonesian});

  static const List<OffsetProject> projects = [
    OffsetProject(
      title: 'Selamatkan Hutan Gambut Kampar',
      imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1200&q=80',
      description: 'Program restorasi hutan gambut seluas 12.000 ha di Kabupaten Kampar, Riau. Gambut menyimpan karbon 10x lebih banyak dari hutan biasa — setiap pohon yang ditanam membantu menahan emisi dan banjir.',
      location: 'Kampar, Riau',
      trees: 45000,
    ),
    OffsetProject(
      title: 'Pulihkan Pesisir Bali',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
      description: 'Rehabilitasi terumbu karang dan penanaman mangrove di pesisir selatan Bali untuk melindungi garis pantai dari abrasi sekaligus menyerap karbon biru (blue carbon).',
      location: 'Pesisir Selatan, Bali',
      trees: 18000,
    ),
    OffsetProject(
      title: 'Desa Bakau Asri',
      imageUrl: 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80',
      description: 'Pemberdayaan masyarakat pesisir melalui kebun bakau komunitas. Ekowisata mangrove yang dikelola warga memberikan penghasilan tambahan sambil menjaga ekosistem.',
      location: 'Karawang, Jawa Barat',
      trees: 22000,
    ),
    OffsetProject(
      title: 'Hijaukan Pesisir Sumatera',
      imageUrl: 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=1200&q=80',
      description: 'Koridor hijau 30 km di pesisir timur Sumatera dengan penanaman bakau dan cemara laut untuk menahan intrusi air laut dan menjadi habitat satwa laut.',
      location: 'Sumatera Timur',
      trees: 31000,
    ),
  ];

  String _projectText(String value) {
    if (isIndonesian) return value;
    const english = <String, String>{
      'Selamatkan Hutan Gambut Kampar': 'Save the Kampar Peat Forest',
      'Pulihkan Pesisir Bali': 'Restore Bali’s Coast',
      'Desa Bakau Asri': 'Green Mangrove Village',
      'Hijaukan Pesisir Sumatera': 'Re-green Sumatra’s Coast',
      'Kampar, Riau': 'Kampar, Riau',
      'Pesisir Selatan, Bali': 'South Coast, Bali',
      'Karawang, Jawa Barat': 'Karawang, West Java',
      'Sumatera Timur': 'East Sumatra',
      'Program restorasi hutan gambut seluas 12.000 ha di Kabupaten Kampar, Riau. Gambut menyimpan karbon 10x lebih banyak dari hutan biasa — setiap pohon yang ditanam membantu menahan emisi dan banjir.': 'A 12,000-hectare peat forest restoration program in Kampar, Riau. Peatlands store 10 times more carbon than ordinary forests, and every tree helps reduce emissions and flooding.',
      'Rehabilitasi terumbu karang dan penanaman mangrove di pesisir selatan Bali untuk melindungi garis pantai dari abrasi sekaligus menyerap karbon biru (blue carbon).': 'Rehabilitating coral reefs and planting mangroves along Bali’s south coast protects shorelines from erosion while absorbing blue carbon.',
      'Pemberdayaan masyarakat pesisir melalui kebun bakau komunitas. Ekowisata mangrove yang dikelola warga memberikan penghasilan tambahan sambil menjaga ekosistem.': 'Empowering coastal communities through shared mangrove gardens. Community-run ecotourism provides extra income while protecting the ecosystem.',
      'Koridor hijau 30 km di pesisir timur Sumatera dengan penanaman bakau dan cemara laut untuk menahan intrusi air laut dan menjadi habitat satwa laut.': 'A 30 km green corridor on Sumatra’s east coast, planted with mangroves and sea pines to limit saltwater intrusion and provide wildlife habitat.',
    };
    return english[value] ?? value;
  }

  void _showProjectDetail(BuildContext context, OffsetProject project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Image.network(
                    project.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: AppColors.deepTeal,
                      child: const Center(
                        child: Icon(
                          Icons.forest_rounded,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _projectText(project.title),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepTeal,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.ecoGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _projectText(project.location),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _projectText(project.description),
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.park_rounded, color: AppColors.deepTeal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isIndonesian
                            ? '${project.trees.toStringAsFixed(0)} pohon telah ditanam melalui Transitify'
                            : '${project.trees.toStringAsFixed(0)} trees planted through Transitify',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showDonationDialog(context, project);
                },
                icon: const Icon(Icons.favorite_rounded),
                label: Text(
                  isIndonesian
                      ? 'DONASI PENANAMAN POHON / NETRALKAN KARBON'
                      : 'DONATE TO TREE PLANTING / CARBON OFFSET',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDonationDialog(BuildContext context, OffsetProject project) {
    var amount = 10000;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isIndonesian
                ? 'Dukung proyek lingkungan'
                : 'Support an environmental project',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_projectText(project.title)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: amount,
                decoration: InputDecoration(
                  labelText: isIndonesian ? 'Nominal demo' : 'Demo amount',
                ),
                items: const [5000, 10000, 25000, 50000]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('Rp ${_formatNumber(value)}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => amount = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                isIndonesian
                    ? 'Simulasi demo saja; tidak ada pembayaran nyata.'
                    : 'Demo simulation only; no real payment will be made.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isIndonesian ? 'Batal' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isIndonesian
                          ? 'Terima kasih! Dukungan demo Rp ${_formatNumber(amount)} untuk "${_projectText(project.title)}" tercatat.'
                          : 'Thank you! Your demo support of Rp ${_formatNumber(amount)} for "${_projectText(project.title)}" was recorded.',
                    ),
                  ),
                );
              },
              child: Text(isIndonesian ? 'Konfirmasi' : 'Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: projects.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIndonesian ? 'Kalkulasi' : 'Offset',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  isIndonesian
                      ? 'Netralkan jejak karbonmu dengan proyek konservasi nyata.'
                      : 'Balance your carbon footprint with real conservation projects.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                SizedBox(height: 18),
              ],
            );
          }
          final p = projects[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showProjectDetail(context, p),
              child: Container(
                height: 190,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          Container(color: AppColors.deepTeal),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _projectText(p.title),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _projectText(p.location),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== TAB 4: ACTIVITY ====================
class ActivityTab extends StatefulWidget {
  final List<TransitTrip> trips;
  final bool isIndonesian;

  const ActivityTab({
    super.key,
    required this.trips,
    required this.isIndonesian,
  });

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  String _filter = 'All Types';

  List<TransitTrip> get _filtered {
    if (_filter == 'All Types') return widget.trips;
    return widget.trips.where((trip) => trip.title == _filter).toList();
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tr('Activity', widget.isIndonesian),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              DropdownButton<String>(
                value: _filter,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(14),
                items: [
                  DropdownMenuItem(
                    value: 'All Types',
                    child: Text(_tr('All Types', widget.isIndonesian)),
                  ),
                  DropdownMenuItem(
                    value: 'KRL Commuter Line',
                    child: Text(_tr('KRL Commuter Line', widget.isIndonesian)),
                  ),
                  DropdownMenuItem(
                    value: 'TransJakarta / BRT',
                    child: Text(_tr('TransJakarta / BRT', widget.isIndonesian)),
                  ),
                  DropdownMenuItem(
                    value: 'MRT Jakarta',
                    child: Text(_tr('MRT Jakarta', widget.isIndonesian)),
                  ),
                  DropdownMenuItem(
                    value: 'Sepeda',
                    child: Text(_tr('Sepeda', widget.isIndonesian)),
                  ),
                  DropdownMenuItem(
                    value: 'Motor',
                    child: Text(_tr('Motor', widget.isIndonesian)),
                  ),
                  DropdownMenuItem(
                    value: 'Mobil',
                    child: Text(_tr('Mobil', widget.isIndonesian)),
                  ),
                  DropdownMenuItem(
                    value: 'Ojol / Ride-hailing',
                    child: Text(
                      _tr('Ojol / Ride-hailing', widget.isIndonesian),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Flight',
                    child: Text(_tr('Flight', widget.isIndonesian)),
                  ),
                  DropdownMenuItem(
                    value: 'Manual Entry',
                    child: Text(_tr('Manual Entry', widget.isIndonesian)),
                  ),
                ],
                onChanged: (v) => setState(() => _filter = v ?? 'All Types'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isIndonesian
                ? 'Hasil (${filtered.length} perjalanan)'
                : 'Results (${filtered.length} trips)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  widget.trips.isEmpty
                      ? (widget.isIndonesian
                            ? 'Belum ada perjalanan. Simpan rute dari Perencana Rute & Transit.'
                            : 'No trips yet. Save a route from Journey & Transit Planner.')
                      : (widget.isIndonesian
                            ? 'Tidak ada aktivitas untuk kategori ini.'
                            : 'No activity for this category.'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...filtered.map(
              (trip) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: AppColors.softGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.mintLight,
                    child: Icon(trip.icon, color: AppColors.deepTeal),
                  ),
                  title: Text(
                    _tr(trip.title, widget.isIndonesian),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${trip.route}\n${trip.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            size: 13,
                            color: trip.carbonEmittedGrams > 0
                                ? Colors.deepOrange.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.isIndonesian
                                  ? 'Dihemat ${(trip.carbonSavedGrams / 1000).toStringAsFixed(2)} kg · '
                                        'Emisi ${(trip.carbonEmittedGrams / 1000).toStringAsFixed(2)} kg · '
                                        'Hemat Rp ${_formatNumber(trip.costSaved)}'
                                  : 'Saved ${(trip.carbonSavedGrams / 1000).toStringAsFixed(2)} kg · '
                                        'Emitted ${(trip.carbonEmittedGrams / 1000).toStringAsFixed(2)} kg · '
                                        'Saved Rp ${_formatNumber(trip.costSaved)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: trip.carbonEmittedGrams > 0
                                    ? Colors.deepOrange.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateLabel(trip.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== TAB 5: ACCOUNT ====================
class AccountTab extends StatefulWidget {
  final String displayName;
  final String username;
  final Uint8List? profileImage;
  final bool isIndonesian;
  final ValueChanged<String> onLanguageChanged;
  final Future<void> Function() onPickProfilePhoto;
  final VoidCallback onLogout;
  final Function(String newName) onProfileChanged;
  final VoidCallback onDeleteAccount;

  const AccountTab({
    super.key,
    required this.displayName,
    required this.username,
    required this.profileImage,
    required this.isIndonesian,
    required this.onLanguageChanged,
    required this.onPickProfilePhoto,
    required this.onLogout,
    required this.onProfileChanged,
    required this.onDeleteAccount,
  });

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  bool _synced = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _setLanguage(String language) {
    widget.onLanguageChanged(language);
    _snack(
      language == 'Bahasa Indonesia'
          ? 'Bahasa diubah ke Bahasa Indonesia.'
          : 'Language switched to English.',
    );
  }

  void _toggleLanguage() {
    _setLanguage(widget.isIndonesian ? 'English' : 'Bahasa Indonesia');
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: widget.displayName);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(_tr('Edit Profile', widget.isIndonesian)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ProfileAvatar(imageBytes: widget.profileImage, radius: 42),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: AppColors.ecoGreen,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: widget.isIndonesian
                            ? 'Pilih foto profil'
                            : 'Choose profile picture',
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () async {
                          await widget.onPickProfilePhoto();
                          setDialogState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: _tr('Full Name', widget.isIndonesian),
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_tr('Cancel', widget.isIndonesian)),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameCtrl.text.trim();
                if (newName.length < 2) {
                  _snack(
                    widget.isIndonesian
                        ? 'Nama lengkap minimal 2 karakter.'
                        : 'Name must be at least 2 characters.',
                  );
                  return;
                }
                widget.onProfileChanged(newName);
                Navigator.pop(ctx);
                _snack(
                  widget.isIndonesian
                      ? 'Profil Transitify berhasil diperbarui!'
                      : 'Profile updated successfully on Transitify!',
                );
              },
              child: Text(_tr('Save', widget.isIndonesian)),
            ),
          ],
        ),
      ),
    ).then((_) => nameCtrl.dispose());
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 36,
          ),
          title: Text(_tr('Delete Account?', widget.isIndonesian)),
          content: Text(
            _tr(
              'This action is permanent. All your Transitify carbon history will be erased.',
              widget.isIndonesian,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_tr('Cancel', widget.isIndonesian)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(ctx);
                widget.onDeleteAccount();
              },
              child: Text(_tr('Delete account', widget.isIndonesian)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                ProfileAvatar(imageBytes: widget.profileImage, radius: 42),
                const SizedBox(height: 12),
                Text(
                  widget.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${widget.username}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Groups section
          Text(
            _tr('Groups', widget.isIndonesian),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _AccountTile(
            icon: Icons.group_add_outlined,
            title: _tr('Create New Group', widget.isIndonesian),
            trailingIcon: Icons.add_circle_outline_rounded,
            onTap: () => _snack(
              widget.isIndonesian
                  ? 'Fitur pembuatan grup dibuka.'
                  : 'Create Group feature opened.',
            ),
          ),
          _AccountTile(
            icon: Icons.login_rounded,
            title: _tr('Join with Invite Code', widget.isIndonesian),
            trailingIcon: Icons.arrow_forward_rounded,
            onTap: () => _snack(
              widget.isIndonesian
                  ? 'Kolom kode undangan dibuka.'
                  : 'Invite code input opened.',
            ),
          ),
          _AccountTile(
            icon: Icons.groups_rounded,
            title: _tr('Your Groups', widget.isIndonesian),
            subtitle: _tr('2 groups joined', widget.isIndonesian),
            onTap: () => _snack(
              widget.isIndonesian
                  ? 'Membuka grup Anda…'
                  : 'Opening your groups…',
            ),
          ),
          const SizedBox(height: 24),

          // General settings
          Text(
            _tr('General Settings', widget.isIndonesian),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _AccountTile(
            icon: Icons.edit_rounded,
            title: _tr('Edit Profile', widget.isIndonesian),
            onTap: _showEditProfileDialog,
          ),
          _AccountTile(
            icon: Icons.photo_camera_outlined,
            title: _tr('Change Profile Picture', widget.isIndonesian),
            onTap: widget.onPickProfilePhoto,
          ),
          _AccountTile(
            icon: Icons.sync_rounded,
            title: _tr('Sync Master Data', widget.isIndonesian),
            trailing: _synced
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.ecoGreen,
                  )
                : null,
            onTap: () {
              setState(() => _synced = true);
              _snack(
                widget.isIndonesian
                    ? 'Data utama berhasil disinkronkan.'
                    : 'Master data synced successfully.',
              );
            },
          ),
          _AccountTile(
            icon: Icons.location_searching_rounded,
            title: _tr('Active Tracking Session', widget.isIndonesian),
            subtitle: _tr('No active session', widget.isIndonesian),
            onTap: () => _snack(
              widget.isIndonesian
                  ? 'Tidak ada sesi pelacakan GPS yang aktif.'
                  : 'No active GPS tracking session.',
            ),
          ),
          _AccountTile(
            icon: Icons.payment_rounded,
            title: _tr('Payment Methods', widget.isIndonesian),
            comingSoon: true,
            comingSoonLabel: widget.isIndonesian
                ? 'SEGERA HADIR'
                : 'COMING SOON',
            onTap: () {},
          ),
          _AccountTile(
            icon: Icons.route_rounded,
            title: _tr('Saved Routes', widget.isIndonesian),
            comingSoon: true,
            comingSoonLabel: widget.isIndonesian
                ? 'SEGERA HADIR'
                : 'COMING SOON',
            onTap: () {},
          ),
          _AccountTile(
            icon: Icons.language_rounded,
            title: _tr('Switch Language', widget.isIndonesian),
            trailing: DropdownButton<String>(
              value: widget.isIndonesian ? 'Bahasa Indonesia' : 'English',
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                  value: 'Bahasa Indonesia',
                  child: Text('Indonesia'),
                ),
                DropdownMenuItem(value: 'English', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) _setLanguage(v);
              },
            ),
            onTap: _toggleLanguage,
          ),
          _AccountTile(
            icon: Icons.logout_rounded,
            title: _tr('Logout', widget.isIndonesian),
            iconColor: Colors.red,
            onTap: widget.onLogout,
          ),
          _AccountTile(
            icon: Icons.delete_forever_rounded,
            title: _tr('Delete Account', widget.isIndonesian),
            iconColor: Colors.red,
            onTap: _showDeleteDialog,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Transitify v1.0.0 — SDG 11',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailingIcon;
  final Widget? trailing;
  final Color iconColor;
  final bool comingSoon;
  final String? comingSoonLabel;
  final VoidCallback onTap;

  const _AccountTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingIcon,
    this.trailing,
    this.iconColor = AppColors.deepTeal,
    this.comingSoon = false,
    this.comingSoonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.softGray,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: comingSoon ? null : onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: comingSoon ? Colors.grey : AppColors.textDark,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (comingSoon)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.deepTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comingSoonLabel ?? 'COMING SOON',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            trailing ??
                Icon(
                  trailingIcon ?? Icons.chevron_right_rounded,
                  color: Colors.grey.shade500,
                ),
          ],
        ),
      ),
    );
  }
}
