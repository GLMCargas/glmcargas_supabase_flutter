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

    if (!mounted) return;
    setState(() => carregando = true);

    var user = supabase.auth.currentUser;

    int tentativas = 0;
    while (user == null && tentativas < 10) {
      await Future.delayed(const Duration(milliseconds: 150));
      user = supabase.auth.currentUser;
      tentativas++;
    }

    if (user == null) {
      if (!mounted) return;
      setState(() {
        carregando = false;
        usuario = null;
        veiculo = null;
      });
      return;
    }

    try {
      final dadosUsuario = await supabase
          .from("Usuario_Caminhoneiro")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      final dadosVeiculo = await supabase
          .from("Veiculo")
          .select()
          .eq("Usuario_CaminhoneiroID", user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        usuario = dadosUsuario;
        veiculo = dadosVeiculo;
        carregando = false;
      });
    } catch (e) {
      print("Erro ao carregar perfil: $e");
      if (!mounted) return;
      setState(() => carregando = false);
    }
  }

  String _formatarData(dynamic valor) {
    if (valor == null) return "-";
    final partes = valor.toString().split("-");
    if (partes.length != 3) return valor.toString();
    return "${partes[2]}/${partes[1]}/${partes[0]}";
  }

  Widget _footerIcon({
    required IconData icon,
    required VoidCallback onTap,
    bool ativo = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: ativo
            ? Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: Colors.white,
                ),
              )
            : Icon(
                icon,
                size: 32,
                color: Colors.black87,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      body: Center(
        child: Stack(
          children: [
            Container(
              width: 430,
              height: MediaQuery.of(context).size.height * 0.95,
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
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.orange,
                          ),
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
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.orange,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() => _menuAberto = true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: carregando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          )
                        : usuario == null
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    "Não foi possível carregar os dados do perfil.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
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
                                      "${usuario!['nome'] ?? ""} ${usuario!['sobrenome'] ?? ""}"
                                          .trim(),
                                      textAlign: TextAlign.center,
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
                                    _linhaInfo(
                                      "Telefone",
                                      usuario!["telefone"],
                                    ),
                                    _linhaInfo(
                                      "Nascimento",
                                      _formatarData(usuario!["data_nascimento"]),
                                    ),
                                    _linhaInfo("Gênero", usuario!["genero"]),
                                    const SizedBox(height: 25),
                                    _secaoTitulo("Veículo cadastrado"),
                                    veiculo == null
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                            child: Text(
                                              "Nenhum veículo cadastrado ainda.",
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              _linhaInfo(
                                                "Tipo do veículo",
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
                                                veiculo!["RNTRC_ANTT"],
                                              ),
                                            ],
                                          ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade300,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _footerIcon(
                          icon: Icons.home_outlined,
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/home'),
                        ),
                        _footerIcon(
                          icon: Icons.person_outline,
                          ativo: true,
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            '/perfilMotorista',
                          ),
                        ),
                        _footerIcon(
                          icon: Icons.chat_bubble_outline,
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/chats'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(valor?.toString() ?? "-"),
          ),
        ],
      ),
    );
  }
}