import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/settings_button.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final users = _query.isEmpty
        ? appState.users
        : appState.users
            .where(
              (u) =>
                  u.fullName.toLowerCase().contains(_query.toLowerCase()) ||
                  u.email.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          const SettingsButton(),
          const LogoutButton(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddUserSheet(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Add Barangay Official'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: users.isEmpty
                ? const EmptyState(
                    icon: Icons.group_off_outlined,
                    title: 'No users found',
                    message: 'Try a different search.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserTile(user: user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddUserSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final barangayController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Barangay Official',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The official will be able to review and resolve complaints.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'e.g. Kagawad Almeda',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: barangayController,
                decoration: const InputDecoration(
                  labelText: 'Barangay',
                  hintText: 'e.g. Barangay Halang',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final password = passwordController.text;
                  final barangay = barangayController.text.trim();

                  if (name.isEmpty ||
                      email.isEmpty ||
                      password.isEmpty ||
                      barangay.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All fields are required'),
                      ),
                    );
                    return;
                  }

                  await context.read<AppState>().addOfficer(
                        fullName: name,
                        email: email,
                        password: password,
                        barangay: barangay,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Create Official Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: user.role.containerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(user.role.icon, size: 20, color: user.role.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleBadge(role: user.role),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Joined ${DateFormat('MMM d, yyyy').format(user.createdAt)}'
                    '${user.barangay != null ? ' · ${user.barangay}' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (user.role != UserRole.admin)
              IconButton(
                onPressed: () => _confirmToggle(context),
                tooltip: user.isActive ? 'Revoke access' : 'Restore access',
                icon: Icon(
                  user.isActive
                      ? Icons.block_outlined
                      : Icons.restore_outlined,
                  color: user.isActive ? AppColors.danger : AppColors.success,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmToggle(BuildContext context) {
    final action = user.isActive ? 'revoke' : 'restore';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action ${user.fullName}?'),
        content: Text(
          user.isActive
              ? 'This user will no longer be able to sign in to CitiSense.'
              : 'This user will regain access to CitiSense.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppState>().toggleUserActive(user);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: user.isActive
                  ? AppColors.danger
                  : AppColors.success,
            ),
            child: Text(action == 'revoke' ? 'Revoke' : 'Restore'),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: role.containerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.shortLabel.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: role.color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
