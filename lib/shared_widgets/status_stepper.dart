// lib/shared_widgets/status_stepper.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/order.dart';

class StatusStepper extends StatelessWidget {
  final OrderStatus currentStatus;
  final bool compact;

  const StatusStepper({
    super.key,
    required this.currentStatus,
    this.compact = false,
  });

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.cancelled) {
      return _CancelledBanner();
    }
    final currentIdx = currentStatus.stepIndex;

    return Column(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIdx = i ~/ 2;
          final done = stepIdx < currentIdx;
          return _StepConnector(done: done);
        }
        final stepIdx = i ~/ 2;
        final step = _steps[stepIdx];
        final done = stepIdx < currentIdx;
        final active = stepIdx == currentIdx;
        return _StepItem(
          status: step,
          done: done,
          active: active,
          compact: compact,
        );
      }),
    );
  }
}

class _StepItem extends StatelessWidget {
  final OrderStatus status;
  final bool done;
  final bool active;
  final bool compact;

  const _StepItem({
    required this.status,
    required this.done,
    required this.active,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    Color textColor;
    Widget circleChild;

    if (done) {
      circleColor = AppColors.success;
      textColor = AppColors.onSurface;
      circleChild = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
    } else if (active) {
      circleColor = AppColors.primary;
      textColor = AppColors.onSurface;
      circleChild = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
    } else {
      circleColor = AppColors.surfaceContainerHighest;
      textColor = AppColors.outline;
      circleChild = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: AppColors.outline.withValues(alpha: 0.4), shape: BoxShape.circle),
      );
    }

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: Center(child: circleChild),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.displayName,
                style: (active
                        ? AppTextStyles.labelMd
                        : AppTextStyles.bodySm)
                    .copyWith(color: textColor),
              ),
              if (active && !compact)
                Text(
                  'In progress...',
                  style: AppTextStyles.labelXs.copyWith(color: AppColors.primary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool done;
  const _StepConnector({required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          child: Center(
            child: Container(
              width: 2,
              height: 28,
              color: done ? AppColors.success : AppColors.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.error),
          const SizedBox(width: 12),
          Text('Order Cancelled',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.error)),
        ],
      ),
    );
  }
}
