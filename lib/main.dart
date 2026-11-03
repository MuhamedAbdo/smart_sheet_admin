import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. استخراج بيانات الاتصال تلقائياً من المشروع الأصلي (smart_sheet)
const String supabaseUrl = 'https://lbvaezdeaisukxqwwrmk.supabase.co';
const String supabaseAnonKey =
    'sb_publishable_Twjk68loXnXuJIJKy1MkNQ_KdP1iKnQ';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة اتصال Supabase باستخدام القيم المستخرجة (url & anonKey / publishableKey)
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  runApp(const SmartSheetAdminApp());
}

class SmartSheetAdminApp extends StatelessWidget {
  const SmartSheetAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Sheet Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
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
      ),
      home: const AdminHomeScreen(),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// توليد كود عشوائي مكون من 6 أرقام
  void _generateRandomCode() {
    final random = Random();
    // رقم عشوائي بين 100000 و 999999
    final code = (100000 + random.nextInt(900000)).toString();
    setState(() {
      _codeController.text = code;
    });
  }

  /// تنفيذ عملية الإرسال والحقن في جدول pairing_codes
  Future<void> _submitCode() async {
    final code = _codeController.text.trim();

    // التحقق من أن الحقل يحتوي على 6 أرقام بالضبط
    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'يرجى إدخال أو توليد كود مكون من 6 أرقام صحيحة',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      // تاريخ الانتهاء بعد 30 يوماً من الوقت الحالي (بصيغة ISO 8601)
      final expiresAt =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();

      // محاولة حذف أي كود قديم لنفس المصنع أولاً لتفادي تعارض المفاتيح، ثم إدراج الكود الجديد
      try {
        await supabase
            .from('pairing_codes')
            .delete()
            .eq('factory_id', 'CP-2026');
      } catch (_) {
        // تجاهل إذا لم يكن هناك كود سابق أو لم تتوفر صلاحية الحذف
      }

      // استعلام INSERT إلى جدول pairing_codes
      await supabase.from('pairing_codes').insert({
        'code': code,
        'factory_id': 'CP-2026',
        'expires_at': expiresAt,
      });

      if (!mounted) return;

      // عند النجاح: أظهر SnackBar باللون الأخضر يؤكد تفعيل الكود، وقم بتفريغ الحقل النصي
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم تفعيل وإرسال الكود ($code) بنجاح!',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );

      _codeController.clear();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'لوحة تحكم المشرف - Super Admin',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  const Text(
                    'متصل',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
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
                          // 1. صورة اللوجو من المسار assets/images/logo_dark.jpg في أعلى الشاشة (بشكل متناسق وأنيق)
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF334155),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/images/logo_dark.jpg',
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      width: 100,
                                      color: const Color(0xFF0F172A),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 40,
                                        color: Colors.white54,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 2. نص واضح ومميز أسفل اللوجو يقول: "المصنع المستهدف: CP-2026"
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.factory_rounded,
                                      color: Color(0xFF38BDF8),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'المصنع المستهدف: ',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF38BDF8),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'CP-2026',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF38BDF8),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // عنوان توضيحي لحقل الكود
                          const Text(
                            'كود الاقتران (6 أرقام):',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 3. حقل نصي (TextField) مخصص للأرقام يقبل 6 أرقام فقط + زر بجواره لتوليد كود عشوائي
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
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 6,
                                    color: Color(0xFF38BDF8),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '------',
                                    hintStyle: TextStyle(
                                      fontSize: 24,
                                      letterSpacing: 6,
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.key_rounded,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // زر توليد كود عشوائي (6 أرقام) ووضعه داخل الحقل النصي فوراً
                              SizedBox(
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _generateRandomCode,
                                  icon: const Icon(Icons.casino_rounded, size: 20),
                                  label: const Text(
                                    'توليد',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF334155),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                        color: Color(0xFF475569),
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

                          const SizedBox(height: 36),

                          // 4. زر رئيسي كبير أسفل الشاشة باسم: "تفعيل وإرسال الكود"
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFF0284C7).withValues(alpha: 0.4),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _isLoading
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 14),
                                          Text(
                                            'جارٍ الإرسال والتفعيل...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send_rounded, size: 20),
                                          SizedBox(width: 10),
                                          Text(
                                            'تفعيل وإرسال الكود',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
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
