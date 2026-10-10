import 'package:flutter/foundation.dart';

/// true عند التشغيل كتطبيق أندرويد أصلي (APK). على الويب تكون القيمة
/// false حتى لو كان المتصفح على هاتف أندرويد.
bool get isAndroidApp =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// تبويب "الاستعلامات" متاح فقط في نسخة الويب ونسخة ويندوز.
/// (لا يظهر في أندرويد ولا iOS ولا macOS/Linux.)
bool get showResearchTab =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.windows;
