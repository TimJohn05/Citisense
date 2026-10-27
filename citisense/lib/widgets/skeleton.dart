import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: const _ShimmerEffect(),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surfaceMuted,
                AppColors.surfaceMuted.withValues(alpha: _animation.value),
                AppColors.surfaceMuted,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LoadingSkeleton(width: 80, height: 16),
            const SizedBox(height: 12),
            const LoadingSkeleton(width: double.infinity, height: 14),
            const LoadingSkeleton(width: double.infinity, height: 14),
            const SizedBox(height: 12),
            Row(
              children: [
                const LoadingSkeleton(width: 60, height: 18),
                const Spacer(),
                const LoadingSkeleton(width: 50, height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MiniStatSkeleton extends StatelessWidget {
  const MiniStatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              const LoadingSkeleton(width: 20, height: 20),
              const SizedBox(height: 6),
              const LoadingSkeleton(width: 40, height: 18),
              const SizedBox(height: 2),
              const LoadingSkeleton(width: 60, height: 11),
            ],
          ),
        ),
      ),
    );
  }
}

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: LoadingSkeleton(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(8))),
      title: LoadingSkeleton(width: 120, height: 16),
      subtitle: LoadingSkeleton(width: 200, height: 12),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  final int miniStatCount;
  final int cardCount;

  const DashboardSkeleton({
    super.key,
    this.miniStatCount = 4,
    this.cardCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        const Row(
          children: [
            LoadingSkeleton(width: 150, height: 20),
            Spacer(),
            LoadingSkeleton(width: 40, height: 40),
            SizedBox(width: 8),
            LoadingSkeleton(width: 40, height: 40),
            SizedBox(width: 8),
            LoadingSkeleton(width: 40, height: 40),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            miniStatCount,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == miniStatCount - 1 ? 0 : 12),
                child: const MiniStatSkeleton(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Reports by category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const LoadingSkeleton(width: double.infinity, height: 180),
        const SizedBox(height: 24),
        const Text('Recent Reports',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...List.generate(cardCount, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const CardSkeleton(),
            )),
      ],
    );
  }
}

class CitizenDashboardSkeleton extends StatelessWidget {
  const CitizenDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(child: LoadingSkeleton(width: 150, height: 20)),
            SizedBox(width: 8),
            LoadingSkeleton(width: 40, height: 40),
            SizedBox(width: 8),
            LoadingSkeleton(width: 40, height: 40),
            SizedBox(width: 8),
            LoadingSkeleton(width: 40, height: 40),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: MiniStatSkeleton()),
            const SizedBox(width: 12),
            const Expanded(child: MiniStatSkeleton()),
            const SizedBox(width: 12),
            const Expanded(child: MiniStatSkeleton()),
            const SizedBox(width: 12),
            const Expanded(child: MiniStatSkeleton()),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Recent Reports',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const CardSkeleton(),
            )),
      ],
    );
  }
}

class MyReportsSkeleton extends StatelessWidget {
  const MyReportsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: LoadingSkeleton(width: 200, height: 48),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              LoadingSkeleton(width: 80, height: 12),
              Spacer(),
              LoadingSkeleton(width: 80, height: 32),
              SizedBox(width: 8),
              LoadingSkeleton(width: 80, height: 32),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, _) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const CardSkeleton(),
            ),
          ),
        ),
      ],
    );
  }
}

class OfficerDashboardSkeleton extends StatelessWidget {
  const OfficerDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Row(
          children: [
            LoadingSkeleton(width: 120, height: 24),
            Spacer(),
            LoadingSkeleton(width: 100, height: 12),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: List.generate(5, (_) => const CardSkeleton()),
        ),
        const SizedBox(height: 20),
        const LoadingSkeleton(width: double.infinity, height: 180),
        const SizedBox(height: 16),
        const LoadingSkeleton(width: double.infinity, height: 200),
        const SizedBox(height: 24),
        const Text('Recent Complaints',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const CardSkeleton(),
            )),
      ],
    );
  }
}

class OfficerComplaintsSkeleton extends StatelessWidget {
  const OfficerComplaintsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 60, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 80, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 80, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 80, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 80, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 80, height: 32)),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 100, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 100, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 100, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 100, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 100, height: 32)),
              Padding(padding: const EdgeInsets.only(right: 8), child: LoadingSkeleton(width: 100, height: 32)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, _) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const CardSkeleton(),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(child: LoadingSkeleton(width: 150, height: 24)),
            const Spacer(),
            const LoadingSkeleton(width: 40, height: 40),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: List.generate(4, (_) => const CardSkeleton()),
        ),
        const SizedBox(height: 16),
        const LoadingSkeleton(width: double.infinity, height: 180),
        const SizedBox(height: 16),
        const LoadingSkeleton(width: double.infinity, height: 180),
        const SizedBox(height: 16),
        const LoadingSkeleton(width: double.infinity, height: 180),
      ],
    );
  }
}

class AdminUsersSkeleton extends StatelessWidget {
  const AdminUsersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(5, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: const CardSkeleton(),
          )),
    );
  }
}

class AdminComplaintsSkeleton extends StatelessWidget {
  const AdminComplaintsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(5, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: const CardSkeleton(),
          )),
    );
  }
}

class AdminLogsSkeleton extends StatelessWidget {
  const AdminLogsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(10, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: const ListTileSkeleton(),
          )),
    );
  }
}

class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
children: List.generate(8, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: const ListTileSkeleton(),
          )),
    );
  }
}