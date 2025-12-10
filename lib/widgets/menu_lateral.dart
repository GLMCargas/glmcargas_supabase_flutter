import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MenuLateral extends StatelessWidget {
  final VoidCallback onClose;

  const MenuLateral({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black26,
            offset: Offset(3, 0),
          )
        ],
      ),
      child: FutureBuilder(
        future: supabase
            .from("Usuario_Caminhoneiro")
            .select()
            .eq("id", user!.id)
            .single(),
        builder: (context, snapshot) {
          final dados = snapshot.data ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOPO
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: dados["foto_url"] != null
                          ? NetworkImage(dados["foto_url"])
                          : null,
                      child: dados["foto_url"] == null
                          ? const Icon(Icons.person, color: Colors.orange)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dados["nome"] ?? "Motorista",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: onClose,
                    )
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ITENS MENU
              _itemMenu(
                icon: Icons.home_outlined,
                label: "Página Inicial",
                onTap: () {
                  Navigator.pushReplacementNamed(context, "/homeMotorista");
                },
              ),

              _itemMenu(
                icon: Icons.person_outline,
                label: "Meu Perfil",
                onTap: () {
                  Navigator.pushReplacementNamed(context, "/perfilMotorista");
                },
              ),

              _itemMenu(
                icon: Icons.logout,
                label: "Sair",
                onTap: () async {
                  await supabase.auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/login", (r) => false);
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
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
