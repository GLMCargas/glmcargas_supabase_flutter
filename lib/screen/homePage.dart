import 'package:app/widgets/menu_lateral.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeMotoristaScreen extends StatefulWidget {
  const HomeMotoristaScreen({Key? key}) : super(key: key);

  @override
  State<HomeMotoristaScreen> createState() => _HomeMotoristaScreenState();
}

class _HomeMotoristaScreenState extends State<HomeMotoristaScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> viagens = [];
  Set<dynamic> cardsAbertos = {};
  bool _menuAberto = false;

  String? ufMotorista;
  String? ufSelecionada;

  final List<String> ufs = const [
    "Todas",
    "AC",
    "AL",
    "AP",
    "AM",
    "BA",
    "CE",
    "DF",
    "ES",
    "GO",
    "MA",
    "MT",
    "MS",
    "MG",
    "PA",
    "PB",
    "PR",
    "PE",
    "PI",
    "RJ",
    "RN",
    "RS",
    "RO",
    "RR",
    "SC",
    "SP",
    "SE",
    "TO",
  ];

  @override
  void initState() {
    super.initState();
    _inicializarHome();
  }

  Future<void> _inicializarHome() async {
    await _carregarUfMotorista();
    await _carregarViagens();
  }

  Future<void> _carregarUfMotorista() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          ufSelecionada = "Todas";
        });
        return;
      }

      final endereco = await supabase
          .from("Endereço")
          .select("UF")
          .eq("Usuario_CaminhoneiroID", user.id)
          .maybeSingle();

      final uf = endereco?["UF"]?.toString().trim().toUpperCase();

      setState(() {
        ufMotorista = uf;
        ufSelecionada = (uf != null && uf.isNotEmpty) ? uf : "Todas";
      });
    } catch (e) {
      debugPrint("❌ Erro ao carregar UF do motorista: $e");
      setState(() {
        ufSelecionada = "Todas";
      });
    }
  }

  Future<void> _carregarViagens() async {
    try {
      dynamic response;

      if (ufSelecionada != null && ufSelecionada != "Todas") {
        response = await supabase
            .from("Viagens")
            .select()
            .eq("origem_uf", ufSelecionada!);
      } else {
        response = await supabase.from("Viagens").select();
      }

      setState(() {
        viagens = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("❌ Erro ao carregar viagens: $e");
    }
  }

  void _toggleCard(dynamic id) {
    setState(() {
      if (cardsAbertos.contains(id)) {
        cardsAbertos.remove(id);
      } else {
        cardsAbertos.add(id);
      }
    });
  }

  Future<void> _abrirChat(int viagemId) async {
    try {
      final roomId = await supabase.rpc(
        'create_or_get_chat_room',
        params: {'p_viagem_id': viagemId},
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {'roomId': roomId.toString()},
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir chat: $e')),
      );
    }
  }

  String formatarData(String iso) {
    try {
      final data = DateTime.parse(iso);
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final ano = data.year;
      final hora = data.hour.toString().padLeft(2, '0');
      final minuto = data.minute.toString().padLeft(2, '0');

      return "$dia/$mes/$ano $hora:$minuto";
    } catch (e) {
      debugPrint("Erro ao formatar data: $e");
      return iso;
    }
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 64,
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
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.orange,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.menu,
                            size: 28,
                            color: Colors.orange,
                          ),
                          onPressed: () => setState(() => _menuAberto = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Cargas disponíveis",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: ufSelecionada ?? "Todas",
                      decoration: InputDecoration(
                        labelText: "Filtrar por UF",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ufs.map((uf) {
                        return DropdownMenuItem<String>(
                          value: uf,
                          child: Text(
                            uf == "Todas" ? "Todas as UFs" : uf,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          ufSelecionada = value ?? "Todas";
                          cardsAbertos.clear();
                        });
                        await _carregarViagens();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: viagens.isEmpty
                        ? const Center(
                            child: Text("Nenhuma carga disponível"),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: viagens.length,
                            itemBuilder: (context, index) {
                              final v = viagens[index];
                              final aberta = cardsAbertos.contains(v["id"]);

                              return GestureDetector(
                                onTap: () => _toggleCard(v["id"]),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: aberta
                                        ? Colors.orange.shade300
                                        : Colors.orange.shade200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.black,
                                            child: Text(
                                              (v["empresa"] ?? "?")
                                                  .toString()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (v["empresa"] ?? "")
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  (v["produto"] ?? "")
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            "${v["origem_uf"] ?? "-"} → ${v["destino_uf"] ?? "-"}",
                                          ),
                                        ],
                                      ),
                                      if (aberta) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          "Dimensões: ${v["dimensoes"] ?? "-"}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text("Peso: ${v["peso"] ?? "-"} kg"),
                                        Text("Valor: R\$ ${v["valor"] ?? "-"}"),
                                        Text(
                                          "Limite de entrega: ${formatarData((v["data_limite_entrega"] ?? "").toString())}",
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () => _abrirChat(
                                              (v["id"] as num).toInt(),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                            ),
                                            child: const Text(
                                              "Bate-papo com a empresa",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      color: Colors.orange.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, "/perfilMotorista");
                            },
                            child: const Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 32,
                              color: Colors.black87,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, "/chats");
                            },
                          ),
                        ],
                      ),
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
}