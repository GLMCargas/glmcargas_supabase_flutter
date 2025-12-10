import 'package:app/widgets/menu_lateral.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilMotoristaScreen extends StatefulWidget {
  const PerfilMotoristaScreen({Key? key}) : super(key: key);

  @override
  State<PerfilMotoristaScreen> createState() => _PerfilMotoristaScreenState();
}

class _PerfilMotoristaScreenState extends State<PerfilMotoristaScreen> {
  Map<String, dynamic>? usuario;
  Map<String, dynamic>? veiculo;
  bool carregando = true;

  bool _menuAberto = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final supabase = Supabase.instance.client;
    var user = supabase.auth.currentUser;

    int tentativas = 0;
    while (user == null && tentativas < 10) {
      await Future.delayed(const Duration(milliseconds: 150));
      user = supabase.auth.currentUser;
      tentativas++;
    }

    if (user == null) return;

    try {
      final dadosUsuario = await supabase
          .from("Usuario_Caminhoneiro")
          .select()
          .eq("id", user.id)
          .single();

      final dadosVeiculo = await supabase
          .from("Veiculo")
          .select()
          .eq("Usuario_CaminhoneiroID", user.id)
          .maybeSingle();

      setState(() {
        usuario = dadosUsuario;
        veiculo = dadosVeiculo;
        carregando = false;
      });
    } catch (e) {
      print("Erro ao carregar perfil: $e");
      setState(() => carregando = false);
    }
  }

  String _formatarData(dynamic valor) {
    if (valor == null) return "-";
    final partes = valor.toString().split("-");
    if (partes.length != 3) return valor.toString();
    return "${partes[2]}/${partes[1]}/${partes[0]}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      body: Center(
        child: Stack(
          children: [
            // =======================================
            // 📱 CONTAINER PRINCIPAL (tela branca)
            // =======================================
            Container(
              width: 430,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ------------------ CABEÇALHO ---------------------
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Botão voltar
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.orange),
                          onPressed: () => Navigator.pop(context),
                        ),

                        const Icon(Icons.local_shipping, color: Colors.orange),
                        const SizedBox(width: 6),
                        const Text(
                          "GLM",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "CARGAS",
                          style: TextStyle(color: Colors.orange, fontSize: 18),
                        ),
                        const Spacer(),

                        // Botão menu
                        IconButton(
                          icon: const Icon(Icons.menu,
                              color: Colors.orange, size: 28),
                          onPressed: () {
                            setState(() => _menuAberto = true);
                          },
                        ),
                      ],
                    ),
                  ),

                  // ------------------ CONTEÚDO ---------------------
                  Expanded(
                    child: carregando || usuario == null
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Colors.orange),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 55,
                                  backgroundImage: usuario!["foto_url"] != null
                                      ? NetworkImage(usuario!["foto_url"])
                                      : null,
                                  child: usuario!["foto_url"] == null
                                      ? const Icon(Icons.person, size: 50)
                                      : null,
                                ),

                                const SizedBox(height: 16),

                                Text(
                                  "${usuario!['nome']} ${usuario!['sobrenome']}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: usuario!['status'] == "Aprovado"
                                        ? Colors.green.shade100
                                        : usuario!['status'] == "Reprovado"
                                            ? Colors.red.shade100
                                            : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Status: ${usuario!['status'] ?? "Pendente"}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                _secaoTitulo("Dados pessoais"),
                                _linhaInfo("Email", usuario!["email"]),
                                _linhaInfo("Telefone",
                                    usuario!["telefone"].toString()),
                                _linhaInfo("Nascimento",
                                    _formatarData(usuario!["data_nascimento"])),
                                _linhaInfo("Gênero", usuario!["genero"]),

                                const SizedBox(height: 25),

                                _secaoTitulo("Veículo cadastrado"),
                                veiculo == null
                                    ? const Text(
                                        "Nenhum veículo cadastrado ainda.")
                                    : Column(
                                        children: [
                                          _linhaInfo("Tipo do veículo",
                                              veiculo!["TipoVeiculo"]),
                                          _linhaInfo("Carroceria",
                                              veiculo!["TipoBau"]),
                                          _linhaInfo("Placa",
                                              veiculo!["PlacaVeiculo"]),
                                          _linhaInfo("RNTRC",
                                              veiculo!["RNTRC_ANTT"]),
                                        ],
                                      ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // =======================================
            // 🍔 MENU LATERAL INTERNO
            // =======================================
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              left: _menuAberto ? 0 : -260,
              top: 0,
              bottom: 0,
              child: MenuLateral(
                onClose: () {
                  setState(() => _menuAberto = false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secaoTitulo(String titulo) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          titulo,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _linhaInfo(String label, dynamic valor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$label:",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(valor?.toString() ?? "-")),
        ],
      ),
    );
  }
}
