import 'package:app/widgets/glm_ui.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: GlmColors.panel,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black26,
            offset: Offset(3, 0),
          ),
        ],
      ),
      child: FutureBuilder(
        future: supabase
            .from('Usuario_Caminhoneiro')
            .select()
            .eq('id', user!.id)
            .single(),
        builder: (context, snapshot) {
          final dados = snapshot.data ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: GlmColors.accent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: dados['foto_url'] != null
                          ? NetworkImage(dados['foto_url'])
                          : null,
                      child: dados['foto_url'] == null
                          ? const Icon(Icons.person, color: GlmColors.accent)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dados['nome'] ?? 'Motorista',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _itemMenu(
                icon: Icons.home_outlined,
                label: 'Página Inicial',
                onTap: () {
                  Navigator.pushNamed(context, '/home');
                },
              ),
              _itemMenu(
                icon: Icons.person_outline,
                label: 'Meu Perfil',
                onTap: () {
                  Navigator.pushNamed(context, '/perfilMotorista');
                },
              ),
              _itemMenu(
                icon: Icons.logout,
                label: 'Sair',
                onTap: () async {
                  await supabase.auth.signOut();
                  if (!context.mounted) return;

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (r) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _itemMenu({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: GlmColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
