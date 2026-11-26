import 'package:flutter/material.dart';

const ink = Color(0xff121212);
const panel = Color(0xff1E1E1E);
const electric = Color(0xff4CAF50); // Green
const amber = Color(0xffFFC107); // Amber
const muted = Color(0xffB0B0B0); // Lighter muted tone

ThemeData courtsideTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: electric,
    onPrimary: ink,
    secondary: amber,
    onSecondary: ink,
    surface: panel,
    onSurface: Color(0xffF3F5FC),
    onSurfaceVariant: muted,
    outline: Color(0xff35415B),
    secondaryContainer: Color(0xff29344C),
  ),
  scaffoldBackgroundColor: ink,
  appBarTheme: const AppBarTheme(
    backgroundColor: ink,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
    ),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    headlineMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
    ),
    titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: panel,
    contentPadding: const EdgeInsets.all(18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xff2B3650)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 56),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  cardTheme: CardThemeData(
    color: panel,
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xff29344C)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xff29344C)),
);

/// A vector court illustration stays crisp at every display density.
class CourtArt extends StatelessWidget {
  const CourtArt({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 2.15,
      child: CustomPaint(painter: _CourtPainter()),
    ),
  );
}

class _CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400, size.height / 186);
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xff253D77), Color(0xff141D32)],
      ).createShader(const Rect.fromLTWH(30, 0, 340, 186));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 186), glow);
    Offset point(double x, double y) =>
        Offset(44 + x * 275 + y * 40, 151 - y * 110);
    final floor = Path()..moveTo(point(0, 0).dx, point(0, 0).dy);
    for (final p in [point(1, 0), point(1, 1), point(0, 1)]) {
      floor.lineTo(p.dx, p.dy);
    }
    floor.close();
    canvas.drawPath(floor, Paint()..color = const Color(0xff22375D));
    canvas.drawPath(
      floor,
      Paint()
        ..color = electric.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (final x in [1 / 3, 2 / 3]) {
      canvas.drawLine(
        point(x, 0),
        point(x, 1),
        Paint()
          ..color = electric.withValues(alpha: .4)
          ..strokeWidth = 1,
      );
    }
    final near = point(.5, 0), far = point(.5, 1);
    final net = Paint()
      ..color = const Color(0xffD8E4FF)
      ..strokeWidth = 1.5;
    canvas.drawLine(near + const Offset(0, 8), near - const Offset(0, 42), net);
    canvas.drawLine(far, far - const Offset(0, 42), net);
    canvas.drawLine(near - const Offset(0, 39), far - const Offset(0, 39), net);
    for (var i = 0; i <= 8; i++) {
      final p = Offset.lerp(near, far, i / 8)!;
      canvas.drawLine(
        p - const Offset(0, 18),
        p - const Offset(0, 39),
        Paint()..color = electric.withValues(alpha: .4),
      );
    }
    for (final y in [18.0, 25.0, 32.0]) {
      canvas.drawLine(
        near - Offset(0, y),
        far - Offset(0, y),
        Paint()..color = electric.withValues(alpha: .4),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(270, 101, 32, 8),
      Paint()..color = ink.withValues(alpha: .5),
    );
    canvas.drawCircle(
      const Offset(286, 70),
      16,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffFFE0A8), amber],
        ).createShader(const Rect.fromLTWH(270, 54, 32, 32)),
    );
    canvas.drawArc(
      const Rect.fromLTWH(274, 54, 22, 32),
      -.8,
      2.7,
      false,
      Paint()
        ..color = const Color(0xff9D6737)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawArc(
      const Rect.fromLTWH(270, 61, 32, 18),
      .1,
      2.8,
      false,
      Paint()
        ..color = const Color(0xff9D6737)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CourtPainter oldDelegate) => false;
}

class HomeLink extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const HomeLink({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Icon(icon, color: electric),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: muted, fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: muted),
      onTap: onTap,
    ),
  );
}
