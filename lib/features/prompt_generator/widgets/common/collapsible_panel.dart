import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';

/// Collapsed-by-default panel for Generate-screen steps and options.
class CollapsiblePanel extends StatefulWidget {
  const CollapsiblePanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon = PhosphorIconsRegular.caretDown,
    this.step,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final int? step;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CollapsiblePanel> createState() => _CollapsiblePanelState();
}

class _CollapsiblePanelState extends State<CollapsiblePanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.accentTertiary.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              hapticLight();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (widget.step != null)
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.accentTertiary,
                            AppColors.creodomeCyan,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.step}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.background,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentTertiary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 16,
                        color: AppColors.accentTertiary,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    _expanded ? 'Hide' : 'Show',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? PhosphorIconsRegular.caretUp
                        : PhosphorIconsRegular.caretDown,
                    size: 16,
                    color: AppColors.accentTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.8),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
