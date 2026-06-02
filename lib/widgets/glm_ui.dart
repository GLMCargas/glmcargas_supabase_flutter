import 'package:flutter/material.dart';

class GlmColors {
  static const background = Color(0xFFFFF2E8);
  static const panel = Colors.white;
  static const accent = Color(0xFFF28C28);
  static const accentStrong = Color(0xFFE16F12);
  static const accentSoft = Color(0xFFFFE1C2);
  static const border = Color(0xFFF3C79B);
  static const textPrimary = Color(0xFF2C2117);
  static const textMuted = Color(0xFF766250);
}

enum GlmBottomNavItem { home, profile, chats }

class GlmShell extends StatelessWidget {
  const GlmShell({
    super.key,
    required this.header,
    required this.body,
    this.bottomNavigation,
    this.overlays = const [],
  });

  final Widget header;
  final Widget body;
  final Widget? bottomNavigation;
  final List<Widget> overlays;

  static const double _frameMaxWidth = 452;
  static const double _frameMaxHeight = 900;
  static const double _outerPadding = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlmColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxFrameWidth = constraints.maxWidth - (_outerPadding * 2);
            final maxFrameHeight = constraints.maxHeight - (_outerPadding * 2);
            final frameWidth = maxFrameWidth < _frameMaxWidth
                ? maxFrameWidth
                : _frameMaxWidth;
            final frameHeight = maxFrameHeight < _frameMaxHeight
                ? maxFrameHeight
                : _frameMaxHeight;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(_outerPadding),
                child: SizedBox(
                  width: frameWidth > 0 ? frameWidth : null,
                  height: frameHeight > 0 ? frameHeight : null,
                  child: Stack(
                    children: [
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: GlmColors.panel,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            header,
                            Expanded(child: body),
                            ?bottomNavigation,
                          ],
                        ),
                      ),
                      ...overlays,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class GlmHeader extends StatelessWidget {
  const GlmHeader({super.key, this.onBack, this.onMenu, this.trailing});

  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final resolvedTrailing =
        trailing ??
        (onMenu != null
            ? IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded, color: GlmColors.accent),
              )
            : const SizedBox(width: 48));

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF6E4D0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: onBack == null
                ? null
                : IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: GlmColors.accent,
                    ),
                  ),
          ),
          const Expanded(child: _GlmBrand()),
          SizedBox(width: 48, child: Center(child: resolvedTrailing)),
        ],
      ),
    );
  }
}

class _GlmBrand extends StatelessWidget {
  const _GlmBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.local_shipping_rounded, color: GlmColors.accent, size: 26),
        SizedBox(width: 8),
        Text(
          'GLM',
          style: TextStyle(
            color: GlmColors.accent,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(width: 4),
        Text(
          'CARGAS',
          style: TextStyle(
            color: GlmColors.accentStrong,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class GlmSectionHeader extends StatelessWidget {
  const GlmSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.centered = true,
  });

  final String title;
  final String? subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.left;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: const TextStyle(
            color: GlmColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: const TextStyle(
              color: GlmColors.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class GlmBottomNavigation extends StatelessWidget {
  const GlmBottomNavigation({super.key, required this.current});

  final GlmBottomNavItem current;

  void _go(BuildContext context, String route, GlmBottomNavItem item) {
    if (current == item) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: GlmColors.accentSoft,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavButton(
            icon: Icons.home_outlined,
            active: current == GlmBottomNavItem.home,
            onTap: () => _go(context, '/home', GlmBottomNavItem.home),
          ),
          _NavButton(
            icon: Icons.person_outline_rounded,
            active: current == GlmBottomNavItem.profile,
            onTap: () =>
                _go(context, '/perfilMotorista', GlmBottomNavItem.profile),
          ),
          _NavButton(
            icon: Icons.chat_bubble_outline_rounded,
            active: current == GlmBottomNavItem.chats,
            onTap: () => _go(context, '/chats', GlmBottomNavItem.chats),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = active
        ? Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: GlmColors.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          )
        : Icon(icon, size: 30, color: GlmColors.textPrimary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

class GlmPrimaryButton extends StatelessWidget {
  const GlmPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
      ),
    );
  }
}

class GlmOutlinedAction extends StatelessWidget {
  const GlmOutlinedAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.upload_file_rounded),
        label: Text(label),
      ),
    );
  }
}

class GlmInfoCard extends StatelessWidget {
  const GlmInfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFBF7),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: GlmColors.border),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class GlmFormPage extends StatelessWidget {
  const GlmFormPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return GlmShell(
      header: GlmHeader(onBack: onBack),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          children: [
            GlmSectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
