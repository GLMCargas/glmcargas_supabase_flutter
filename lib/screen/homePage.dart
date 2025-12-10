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
  Set<int> cardsAbertos = {};

  bool _menuAberto = false; 

  @override
  void initState() {
    super.initState();
    _carregarViagens();
  }

  Future<void> _carregarViagens() async {
    try {
      final response = await supabase.from("Viagens").select();
      setState(() {
        viagens = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("❌ Erro ao carregar viagens: $e");
    }
  }

  void _toggleCard(int id) {
    setState(() {
      cardsAbertos.contains(id)
          ? cardsAbertos.remove(id)
          : cardsAbertos.add(id);
    });
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
    print("Erro ao formatar data: $e");
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                          style: TextStyle(fontSize: 18, color: Colors.orange),
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
                    "Cargas disponíveis na sua região",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: viagens.isEmpty
                        ? const Center(child: Text("Nenhuma carga disponível"))
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
                                              v["empresa"][0],
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v["empresa"],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                v["produto"],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            "${v["origem_uf"]} → ${v["destino_uf"]}",
                                          ),
                                        ],
                                      ),

                                      if (aberta) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          "Dimensões: ${v["dimensoes"]}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text("Peso: ${v["peso"]} kg"),
                                        Text("Valor: R\$ ${v["valor"]}"),
                                        Text(
                                          "Limite de entrega: ${formatarData(v["data_limite_entrega"])}",
                                        ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () {},
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
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 32,
                            color: Colors.black87,
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
