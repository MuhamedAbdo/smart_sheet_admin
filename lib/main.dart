import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. استخراج بيانات الاتصال تلقائياً من المشروع الأصلي (smart_sheet)
const String supabaseUrl = 'https://lbvaezdeaisukxqwwrmk.supabase.co';
const String supabaseAnonKey = 'sb_publishable_Twjk68loXnXuJIJKy1MkNQ_KdP1iKnQ';

const String _kThemePrefKey = 'is_dark_theme';

/// مدير الثيم (ThemeMode) للتحكم الفوري بالتبديل بين الوضع المظلم والمضيء
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.dark,
);

/// تبديل الثيم وحفظ الإعداد في SharedPreferences
Future<void> toggleTheme() async {
  final isCurrentDark = themeNotifier.value == ThemeMode.dark;
  final newMode = isCurrentDark ? ThemeMode.light : ThemeMode.dark;
  themeNotifier.value = newMode;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThemePrefKey, newMode == ThemeMode.dark);
  } catch (e) {
    debugPrint('⚠️ Error saving theme preference: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. قراءة الثيم المحفوظ وتطبيقه قبل رسم الشاشة الرئيسية
  try {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kThemePrefKey) ?? true;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  } catch (e) {
    debugPrint('⚠️ Error loading theme preference: $e');
  }

  // تهيئة اتصال Supabase باستخدام القيم المستخرجة (url & anonKey / publishableKey)
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(const SmartSheetAdminApp());
}

/// التطبيق الرئيسي مع دعم الوضعين المظلم والمضيء
class SmartSheetAdminApp extends StatelessWidget {
  const SmartSheetAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // إعدادات الثيم المظلم (Dark Theme) - متناسقة مع ألوان التصميم الاحترافي الحالي
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38BDF8), // Sky Blue Accent
        secondary: Color(0xFF0284C7),
        surface: Color(0xFF1E293B), // Slate 800
        error: Color(0xFFEF4444),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );

    // إعدادات الثيم المضيء (Light Theme) - بألوان هادئة ومريحة للعين
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0284C7), // Deep Sky Blue
        secondary: Color(0xFF0EA5E9),
        surface: Colors.white,
        error: Color(0xFFDC2626),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        color: Color(0xFFE9E1DB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        elevation: 2,
        shadowColor: const Color(0x1A0F172A),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Smart Sheet Admin',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// 4. شاشة البداية الديناميكية ملء الشاشة (Splash Screen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // الانتقال التلقائي إلى شاشة توليد الأكواد بعد مرور 3 ثوانٍ
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, _, _) => const GeneratorScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/images/logo_dark.webp'
        : 'assets/images/logo_light.webp';

    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          logoAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              child: Center(
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// شاشة توليد الأكواد وإدارتها (GeneratorScreen / AdminHomeScreen)
typedef AdminHomeScreen = GeneratorScreen;

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// 1. نسخ الكود إلى الحافظة (Clipboard) مع إظهار SnackBar تأكيدي
  Future<void> _copyCodeToClipboard() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'يرجى توليد الكود أولاً للتمكن من نسخه',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم نسخ الكود ($code) إلى الحافظة بنجاح!',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF15803D), // Green 700
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 1. مشاركة الكود مباشرة عبر تطبيق واتساب (WhatsApp Share)
  Future<void> _shareCodeViaWhatsApp() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'يرجى توليد الكود أولاً للمشاركة عبر واتساب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // 2. كود عام بدون تقييد بمصنع
    final message = 'كود الدخول العام لتطبيق Smart Sheet هو: $code';
    final whatsappUri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تعذر فتح تطبيق واتساب. يرجى التأكد من تثبيت التطبيق.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء محاولة فتح واتساب: $e',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// 1. توليد كود عشوائي مكون من 6 أرقام وإرساله وتفعيله فوراً في Supabase بضغطة واحدة
  Future<void> _generateAndSubmitCode() async {
    // أ. توليد كود عشوائي مكون من 6 أرقام وإظهاره في الحقل
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();

    setState(() {
      _codeController.text = code;
      _isLoading = true;
    });

    // ب. إرسال استعلام INSERT إلى Supabase فوراً بهذا الكود ككود عام (Global Code)
    try {
      final supabase = Supabase.instance.client;
      // تاريخ الانتهاء بعد 30 يوماً بتوقيت UTC لمنع مشاكل المنطقة الزمنية
      final expiresAt = DateTime.now()
          .toUtc()
          .add(const Duration(days: 30))
          .toIso8601String();

      // 1. تفعيل كود الدعوة لبوابة الدخول (Gatekeeper / validate_invitation_code RPC)
      try {
        await supabase.rpc('create_invitation', params: {'new_code': code});
      } catch (rpcError) {
        debugPrint('⚠️ create_invitation RPC info: $rpcError');
      }

      // 2. محاولة حذف أي كود مكرر أولاً لتفادي تعارض المفاتيح
      try {
        await supabase.from('pairing_codes').delete().eq('code', code);
      } catch (_) {
        // تجاهل إذا لم تتوفر صلاحية الحذف
      }

      // 3. إدراج الكود في جدول pairing_codes ككود عام فقط (code, is_used: false, expires_at)
      try {
        await supabase.from('pairing_codes').insert({
          'code': code,
          'is_used': false,
          'expires_at': expiresAt,
        });
      } catch (_) {
        // في حال كان عمود is_used غير موجود في جدول pairing_codes
        try {
          await supabase.from('pairing_codes').insert({
            'code': code,
            'expires_at': expiresAt,
          });
        } catch (insertError) {
          debugPrint('⚠️ pairing_codes insert error: $insertError');
        }
      }

      if (!mounted) return;

      // ج. إظهار رسالة النجاح (SnackBar) عند إتمام الإرسال
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم توليد وتفعيل الكود ($code) بنجاح!',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF15803D), // Green 700
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      String errorMessage = error.toString();
      if (errorMessage.contains('42501') ||
          errorMessage.contains('row-level security policy')) {
        errorMessage =
            'خطأ في صلاحيات قاعدة البيانات (RLS): يجب تفعيل سياسة السماح لجدول pairing_codes في Supabase.';
      }

      // عند الفشل: أظهر SnackBar باللون الأحمر يعرض تفاصيل الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'فشل في تفعيل الكود: $errorMessage',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626), // Red 600
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 3. الأيقونة الديناميكية في الشاشة الرئيسية أعلى حقل إدخال الكود
    final drawerLogoAsset = isDark
        ? 'assets/images/appdrawer_dark.webp'
        : 'assets/images/appdrawer_light.webp';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('لوحة تحكم المشرف - Super Admin'),
          ),
          actions: [
            // 2. زر تبديل (Toggle) في الـ AppBar للتبديل الفوري بين الوضع المظلم والمضيء وحفظه في SharedPreferences
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                final isCurrentDark = currentMode == ThemeMode.dark;
                return IconButton(
                  tooltip: isCurrentDark
                      ? 'التحويل للوضع المضيء'
                      : 'التحويل للوضع المظلم',
                  icon: Icon(
                    isCurrentDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: isCurrentDark
                        ? const Color(0xFFFBBF24) // Amber sun
                        : const Color(0xFF0284C7),
                  ),
                  onPressed: toggleTheme,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 6.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E), // Online green dot
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'متصل',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 3. اللوجو الديناميكي داخل CircleAvatar مع إخفاء الدائرة السوداء تماماً
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.3)
                                        : const Color(
                                            0xFF0F172A,
                                          ).withValues(alpha: 0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                child: ClipOval(
                                  child: Transform.scale(
                                    scale:
                                        1.25, // قص وتجاوز الدائرة والحواف السوداء المحيطة بحواف اللوجو
                                    child: Image.asset(
                                      drawerLogoAsset,
                                      width: 104,
                                      height: 104,
                                      cacheWidth: 300,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.dashboard_customize_rounded,
                                              size: 44,
                                              color: primaryColor,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // عنوان حقل الكود
                          Text(
                            'كود الاقتران (6 أرقام):',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // حقل نصي مخصص للأرقام يقبل 6 أرقام فقط + زر بجواره لتوليد كود عشوائي وتفعيله مباشرة
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // حقل الإدخال
                              Expanded(
                                child: TextFormField(
                                  controller: _codeController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 6,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 6,
                                    color: primaryColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '------',
                                    hintStyle: TextStyle(
                                      fontSize: 24,
                                      letterSpacing: 6,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : const Color(0xFF94A3B8),
                                    ),
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.key_rounded,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // زر توليد كود عشوائي وتفعيله مباشرة بضغطة واحدة
                              SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _generateAndSubmitCode,
                                  icon: _isLoading
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  isDark
                                                      ? Colors.white
                                                      : const Color(0xFF1E293B),
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.casino_rounded,
                                          size: 20,
                                        ),
                                  label: const Text(
                                    'توليد',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                    foregroundColor: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF475569)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 1. صفا متناسقا من الأزرار (Row): زر نسخ الكود وزر المشاركة عبر الواتساب
                          Row(
                            children: [
                              // زر نسخ الكود إلى الحافظة
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _copyCodeToClipboard,
                                    icon: const Icon(
                                      Icons.copy_rounded,
                                      size: 19,
                                    ),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'نسخ الكود',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF0284C7),
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(
                                                0xFF38BDF8,
                                              ).withValues(alpha: 0.6)
                                            : const Color(
                                                0xFF0284C7,
                                              ).withValues(alpha: 0.6),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: isDark
                                          ? const Color(
                                              0xFF38BDF8,
                                            ).withValues(alpha: 0.08)
                                          : const Color(
                                              0xFF0284C7,
                                            ).withValues(alpha: 0.06),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // زر مشاركة الكود عبر الواتساب
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: _shareCodeViaWhatsApp,
                                    icon: const Icon(
                                      Icons.chat_rounded,
                                      size: 19,
                                      color: Colors.white,
                                    ),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'واتساب',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF25D366,
                                      ), // WhatsApp Official Green
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      shadowColor: const Color(
                                        0xFF25D366,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
