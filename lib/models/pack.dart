import 'package:flutter/material.dart';

/// حزمة أسئلة. كل الحزم مجانية — لا تمييز مدفوع ولا محتوى مقفل.
///
/// الحزم نوعان: **مدمجة** تأتي مع التطبيق، و**مخصصة** ينشئها المستخدم
/// باسم من اختياره وتُحفظ محليًا.
@immutable
class Pack {
  const Pack({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  /// الحزم المخصصة وحدها يمكن تعديلها وحذفها.
  final bool isCustom;

  /// ألوان هادئة للحزم المخصصة، تُوزَّع بثبات حسب المعرّف.
  static const List<Color> _customPalette = [
    Color(0xFF9B8AA6),
    Color(0xFF7E9AA6),
    Color(0xFFA69279),
    Color(0xFF8AA68F),
    Color(0xFFA6848A),
  ];

  factory Pack.custom({required String id, required String name}) => Pack(
        id: id,
        name: name,
        description: 'فئة أنشأتها بنفسك',
        icon: Icons.label_outline_rounded,
        color: _customPalette[id.hashCode.abs() % _customPalette.length],
        isCustom: true,
      );

  Pack copyWith({String? name}) => Pack(
        id: id,
        name: name ?? this.name,
        description: description,
        icon: icon,
        color: color,
        isCustom: isCustom,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Pack.fromJson(Map<String, dynamic> json) => Pack.custom(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  /// الحزم التي تأتي مع التطبيق — لا تُحذف ولا يُعاد تسميتها.
  static const List<Pack> builtIn = [
    Pack(
      id: 'football',
      name: 'كرة القدم',
      description: 'الدوريات الكبرى، اللاعبون، الانتقالات والتشكيلات',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF6FA88C),
    ),
    Pack(
      id: 'religion',
      name: 'الدين الإسلامي',
      description: 'القرآن، الغزوات، الصحابة والسيرة النبوية',
      icon: Icons.mosque_rounded,
      color: Color(0xFF7FA6A0),
    ),
    Pack(
      id: 'history',
      name: 'التاريخ والسياسة',
      description: 'أحداث، حروب، معاهدات وشخصيات سياسية',
      icon: Icons.account_balance_rounded,
      color: Color(0xFFC9A961),
    ),
    Pack(
      id: 'geography',
      name: 'الجغرافيا',
      description: 'الحدود والجوار، العواصم، التضاريس وأسئلة الترتيب',
      icon: Icons.public_rounded,
      color: Color(0xFF8FA6B5),
    ),
    Pack(
      id: 'misc',
      name: 'المنوعات',
      description: 'دول وأعلام، علوم، حيوانات، جغرافيا وأكثر',
      icon: Icons.travel_explore_rounded,
      color: Color(0xFF7FA6C9),
    ),
    Pack(
      id: 'series',
      name: 'المسلسلات العربية والسورية',
      description: 'باب الحارة، ضيعة ضايعة، ممثلون وجمل مشهورة',
      icon: Icons.live_tv_rounded,
      color: Color(0xFFB5796B),
    ),
  ];

  /// سجل الحزم المخصصة المحمّلة من التخزين.
  ///
  /// نحتفظ به هنا حتى يبقى [byId] متاحًا من أي مكان دون تمرير providers،
  /// تمامًا كما يفعل مستودع الأسئلة مع الأسئلة المخصصة.
  static List<Pack> _custom = const [];

  static void setCustom(List<Pack> packs) =>
      _custom = List.unmodifiable(packs);

  static List<Pack> get all => [...builtIn, ..._custom];

  /// الحزمة الافتراضية عند معرّف غير معروف.
  static Pack get fallback => builtIn.firstWhere((p) => p.id == 'misc');

  static Pack byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => fallback);

  static bool exists(String id) => all.any((p) => p.id == id);
}
