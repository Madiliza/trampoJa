import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// Certifique-se de que este caminho está correto para o seu arquivo JobModel.dart
import 'package:trampoja_app/models/JobModel.dart';
import 'package:firebase_core/firebase_core.dart'; // Necessário para Firebase.initializeApp
// import 'firebase_options.dart'; // Descomente e gere este arquivo com 'flutterfire configure'

// Definição das cores da paleta
const Color laranjaVivo = Color(0xFFFF6F00); // Cor principal, botões, destaques
const Color laranjaSuave = Color(
  0xFFFFA040,
); // Hover, ícones, realces secundários
const Color pessegoClaro = Color(
  0xFFFEE0B2,
); // Fundo de seções, cartões, contrastes
const Color cinzaEscuro = Color(0xFF333333); // Texto principal, títulos
const Color cinzaClaro = Color(0xFFF5F5F5); // Fundo principal, áreas neutras
const Color branco = Color(0xFFFFFFFF); // Fundo, espaços em branco, contraste

/// A tela principal para exibir e gerenciar vagas.
class JobScreen extends StatefulWidget {
  const JobScreen({super.key}); // Use const para o construtor

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  // Instância do Firestore para interagir com o banco de dados
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controladores para os campos de texto do formulário de criação de vaga
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController =
      TextEditingController(); // Novo controlador para o valor

  /// Adiciona uma nova vaga à coleção 'jobs' no Firestore.
  /// Limpa os campos do formulário e fecha o diálogo após a adição.
  void _addJob() async {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty) {
      final double? jobValue = double.tryParse(
        _valueController.text.replaceAll(',', '.'),
      );

      final newJob = Job(
        title: _titleController.text,
        description: _descriptionController.text,
        value: jobValue,
      );

      try {
        // Adiciona um novo documento à coleção 'jobs' com os dados da nova vaga
        await _firestore.collection('jobs').add(newJob.toFirestore());
        // Verifica se o widget ainda está montado antes de usar o context
        if (!mounted) return;
        _titleController.clear();
        _descriptionController.clear();
        _valueController.clear();
        Navigator.of(context).pop(); // Fecha o diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga criada com sucesso!')),
        );
      } catch (e) {
        // Em caso de erro, imprime no console e mostra um SnackBar.
        print('Erro ao adicionar vaga: $e');
        // Verifica se o widget ainda está montado antes de usar o context
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar vaga: $e')),
        );
      }
    } else {
      // Mostra um SnackBar se os campos obrigatórios não forem preenchidos
      // Verifica se o widget ainda está montado antes de usar o context
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o título e a descrição da vaga.')),
      );
    }
  }

  /// Exibe um diálogo para o usuário criar uma nova vaga.
  void _showCreateJobDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: branco, // Fundo do diálogo
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ), // Cantos arredondados
          title: const Text(
            'Criar Nova Vaga',
            style: TextStyle(color: cinzaEscuro, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título da Vaga',
                    labelStyle: const TextStyle(color: cinzaEscuro),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: laranjaSuave,
                      ), // Borda quando não focado
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: laranjaVivo,
                        width: 2,
                      ), // Borda quando focado
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: cinzaClaro.withOpacity(
                      0.5,
                    ), // Leve preenchimento
                  ),
                  cursorColor: laranjaVivo, // Cor do cursor
                  style: const TextStyle(
                    color: cinzaEscuro,
                  ), // Estilo do texto digitado
                ),
                const SizedBox(height: 15), // Espaçamento entre os campos
                TextField(
                  controller: _descriptionController,
                  maxLines: 3, // Permite múltiplas linhas para a descrição
                  decoration: InputDecoration(
                    labelText: 'Descrição da Vaga',
                    labelStyle: const TextStyle(color: cinzaEscuro),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: laranjaSuave),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: laranjaVivo, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: cinzaClaro.withOpacity(0.5),
                  ),
                  cursorColor: laranjaVivo,
                  style: const TextStyle(color: cinzaEscuro),
                ),
                const SizedBox(height: 15), // Espaçamento entre os campos
                TextField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ), // Teclado numérico com suporte a decimal
                  decoration: InputDecoration(
                    labelText: 'Valor (R\$)', // Novo campo para o valor
                    labelStyle: const TextStyle(color: cinzaEscuro),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: laranjaSuave),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: laranjaVivo, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: cinzaClaro.withOpacity(0.5),
                  ),
                  cursorColor: laranjaVivo,
                  style: const TextStyle(color: cinzaEscuro),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo sem salvar
                _titleController.clear(); // Limpa os campos ao cancelar
                _descriptionController.clear();
                _valueController.clear();
              },
              child: Text('Cancelar', style: TextStyle(color: cinzaEscuro)),
            ),
            ElevatedButton(
              onPressed: _addJob, // Chama a função para adicionar a vaga
              style: ElevatedButton.styleFrom(
                backgroundColor: laranjaVivo, // Cor de fundo do botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ), // Cantos arredondados
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Criar Vaga',
                style: TextStyle(
                  color: branco,
                  fontWeight: FontWeight.bold,
                ), // Texto do botão
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cinzaClaro, // Cor de fundo principal da tela
      appBar: AppBar(
        title: Text(
          'Vagas Disponíveis',
          style: TextStyle(color: branco, fontWeight: FontWeight.bold),
        ),
        backgroundColor: laranjaVivo, // Cor da barra superior
        elevation: 0, // Remove a sombra da barra superior
        centerTitle: true, // Centraliza o título
      ),
      // StreamBuilder para ouvir as mudanças na coleção 'jobs' em tempo real
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar vagas: ${snapshot.error}',
                style: TextStyle(color: cinzaEscuro),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: laranjaVivo));
          }

          // Mapeia os documentos do Firestore para objetos Job
          final jobs = snapshot.data!.docs.map((doc) {
            return Job.fromFirestore(doc); // Usa o construtor de fábrica atualizado
          }).toList();

          if (jobs.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma vaga disponível no momento. Crie uma!',
                style: TextStyle(fontSize: 18, color: cinzaEscuro),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0), // Preenchimento da lista
            itemCount: jobs.length, // Número de itens na lista
            itemBuilder: (context, index) {
              final job = jobs[index]; // Pega a vaga atual do stream do Firestore
              return Card(
                color: pessegoClaro, // Cor de fundo do cartão da vaga
                margin: const EdgeInsets.only(
                  bottom: 16.0,
                ), // Margem inferior para cada cartão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ), // Cantos arredondados
                elevation: 4, // Sombra do cartão
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cinzaEscuro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: cinzaEscuro.withOpacity(
                            0.8,
                          ), // Texto com opacidade para contraste
                        ),
                      ),
                      if (job.value != null) // Mostra o valor se ele existir
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Valor: R\$ ${job.value!.toStringAsFixed(2).replaceAll('.', ',')}', // Formata para 2 casas decimais e usa vírgula
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: laranjaVivo, // Cor do valor
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .end, // Alinha os botões à direita
                        children: [
                          // Exibe os botões "Aceitar" e "Recusar" apenas se a vaga não foi aceita ou recusada
                          if (!job.accepted && !job.declined)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Atualiza o status da vaga no Firestore
                                  try {
                                    await _firestore
                                        .collection('jobs')
                                        .doc(job.id)
                                        .update({
                                      'accepted': true,
                                      'declined': false,
                                    });
                                    // Verifica se o widget ainda está montado antes de usar o context
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vaga aceita com sucesso!')),
                                    );
                                  } catch (e) {
                                    print('Erro ao aceitar vaga: $e');
                                    // Verifica se o widget ainda está montado antes de usar o context
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao aceitar vaga: $e')),
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.check,
                                  color: branco,
                                ), // Ícone de check
                                label: Text(
                                  'Aceitar',
                                  style: TextStyle(color: branco),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      laranjaVivo, // Cor de fundo do botão "Aceitar"
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          if (!job.accepted && !job.declined)
                            const SizedBox(
                              width: 10,
                            ), // Espaçamento entre os botões
                          if (!job.accepted && !job.declined)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Atualiza o status da vaga no Firestore
                                  try {
                                    await _firestore
                                        .collection('jobs')
                                        .doc(job.id)
                                        .update({
                                      'declined': true,
                                      'accepted': false,
                                    });
                                    // Verifica se o widget ainda está montado antes de usar o context
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vaga recusada com sucesso!')),
                                    );
                                  } catch (e) {
                                    print('Erro ao recusar vaga: $e');
                                    // Verifica se o widget ainda está montado antes de usar o context
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao recusar vaga: $e')),
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: cinzaEscuro,
                                ), // Ícone de fechar
                                label: Text(
                                  'Recusar',
                                  style: TextStyle(color: cinzaEscuro),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      laranjaSuave, // Cor de fundo do botão "Recusar"
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          // Exibe o status "Vaga Aceita!" se a vaga foi aceita
                          if (job.accepted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors
                                    .green
                                    .shade100, // Fundo verde claro
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Vaga Aceita!',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Exibe o status "Vaga Recusada!" se a vaga foi recusada
                          if (job.declined)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors
                                    .red
                                    .shade100, // Fundo vermelho claro
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Vaga Recusada!',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateJobDialog, // Abre o diálogo para criar nova vaga
        backgroundColor: laranjaVivo, // Cor do botão flutuante
        child: const Icon(Icons.add, color: branco), // Ícone de adicionar
      ),
    );
  }
}