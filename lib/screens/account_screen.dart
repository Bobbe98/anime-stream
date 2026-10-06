import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/cards.dart';

const avatarIcons = [
  Icons.face,
  Icons.pets,
  Icons.rocket_launch,
  Icons.local_fire_department,
  Icons.auto_awesome,
  Icons.sports_esports,
];

const avatarColors = [
  AppColors.accent,
  AppColors.accent2,
  Color(0xFF06B6D4),
  Color(0xFFF97316),
  Color(0xFF22C55E),
  Color(0xFFEAB308),
];

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.index, this.radius = 36});

  final int index;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final i = index % avatarIcons.length;
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColors[i],
      child: Icon(avatarIcons[i], color: Colors.white, size: radius),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => _pickAvatar(context, state),
              child: Stack(
                children: [
                  ProfileAvatar(index: state.avatar, radius: 44),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.surfaceHigh,
                      child: Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => _editName(context, state),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(
                state.profileName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _PremiumCard(premium: state.premium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Stat(value: '${state.watchlist.length}', label: 'In lista'),
                _Stat(
                  value: '${state.history.where(state.isWatched).length}',
                  label: 'Episodi visti',
                ),
                _Stat(
                  value: '${state.continueWatching.length}',
                  label: 'In corso',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const _SectionTitle('Riproduzione'),
          SwitchListTile(
            secondary: const Icon(Icons.play_circle_outline),
            title: const Text('Riproduzione automatica'),
            subtitle: const Text(
              'Avvia il prossimo episodio alla fine di quello attuale',
            ),
            value: state.autoplay,
            onChanged: (v) => state.autoplay = v,
          ),
          const _SectionTitle('Dati'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Cancella cronologia e progressi'),
            onTap: () {
              state.clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cronologia cancellata')),
              );
            },
          ),
          const _SectionTitle('Informazioni'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Info su AniWave'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'AniWave',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.waves, color: AppColors.accent),
              children: const [
                Text(
                  'App dimostrativa di streaming anime. Serie e copertine sono '
                  'inventate; i video di prova sono cortometraggi open della '
                  'Blender Foundation (licenza Creative Commons).',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, AppState state) async {
    final controller = TextEditingController(text: state.profileName);
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Nome profilo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          onSubmitted: (v) => Navigator.pop(d, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, controller.text),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) state.profileName = name;
  }

  void _pickAvatar(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < avatarIcons.length; i++)
              GestureDetector(
                onTap: () {
                  state.avatar = i;
                  Navigator.pop(sheet);
                },
                child: ProfileAvatar(index: i, radius: 32),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.premium});

  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: premium
            ? const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFF78350F)],
              )
            : AppColors.brandGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, size: 40, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premium ? 'AniWave Fan attivo' : 'Passa a AniWave Fan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  premium
                      ? 'Tutti gli episodi sbloccati (demo)'
                      : 'Sblocca ogni episodio, senza pubblicità',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (premium)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => context.read<AppState>().premium = false,
              child: const Text('Disattiva'),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () => showPremiumSheet(context),
              child: const Text('Prova'),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
