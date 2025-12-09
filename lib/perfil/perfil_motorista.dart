import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/screen/cadastro.dart';

class PerfilMotoristaScreen extends StatefulWidget {
  const PerfilMotoristaScreen({Key? key}) : super(key: key);

  @override
  State<PerfilMotoristaScreen> createState() => _PerfilMotoristaScreenState();
}

class _PerfilMotoristaScreenState extends State<PerfilMotoristaScreen> {
  Map<String, dynamic>? usuario;
  Map<String, dynamic>? veiculo;
  bool carregando = true;

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

    final uid = user.id;

    try {
      // Buscar dados do motorista
      final dadosUsuario = await supabase
          .from("Usuario_Caminhoneiro")
          .select()
          .eq("id", user.id)
          .single();

      // Buscar veículo
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

    String iso;
    if (valor is DateTime) {
      iso = valor.toIso8601String().substring(0, 10);
    } else {
      iso = valor.toString();
    }

    final partes = iso.split("-");
    if (partes.length != 3) return iso;

    final ano = partes[0];
    final mes = partes[1];
    final dia = partes[2];

    return "$dia/$mes/$ano";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
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
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.local_shipping, color: Colors.orange),
                    SizedBox(width: 6),
                    Text(
                      "GLM",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "CARGAS",
                      style: TextStyle(color: Colors.orange, fontSize: 18),
                    ),
                    Spacer(),
                    Icon(Icons.menu, color: Colors.orange, size: 28),
                  ],
                ),
              ),

              Expanded(
                child: carregando || usuario == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
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
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: usuario!['status'] == "Aprovado"
                                  ? BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : usuario!['status'] == "Reprovado"
                                  ? BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : BoxDecoration(
                                      color: Colors.orange.shade100,
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
                            _linhaInfo(
                              "Telefone",
                              usuario!["telefone"].toString(),
                            ),
                            _linhaInfo(
                              "Nascimento",
                              _formatarData(usuario!["data_nascimento"]),
                            ),
                            _linhaInfo("Gênero", usuario!["genero"]),

                            const SizedBox(height: 25),

                            _secaoTitulo("Veículo cadastrado"),

                            veiculo == null
                                ? const Text("Nenhum veículo cadastrado ainda.")
                                : Column(
                                    children: [
                                      _linhaInfo(
                                        "Tipo do Veículo",
                                        veiculo!["TipoVeiculo"],
                                      ),
                                      _linhaInfo(
                                        "Carroceria",
                                        veiculo!["TipoBau"],
                                      ),
                                      _linhaInfo(
                                        "Placa",
                                        veiculo!["PlacaVeiculo"],
                                      ),
                                      _linhaInfo(
                                        "RNTRC",
                                        veiculo!["RNTRC_ANTT"].toString(),
                                      ),
                                    ],
                                  ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
              ),
            ],
          ),
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

  Widget _linhaInfo(String label, String valor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}
