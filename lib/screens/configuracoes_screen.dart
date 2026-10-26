import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ConfiguracoesScreen extends StatefulWidget {
  final Function(bool) onTemaAlterado;

  const ConfiguracoesScreen({super.key, required this.onTemaAlterado});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _service = PreferencesService();
  final _nomeController = TextEditingController();
  final _novaTarefaController = TextEditingController();

  bool _modoEscuro = false;
  bool _carregando = true;
  String? _ultimoAcesso;
  List<Map<String, dynamic>> _tarefas = [];

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _novaTarefaController.dispose();
    super.dispose();
  }

  Future<void> _carregarPreferencias() async {
    final nome = await _service.obterNomeUsuario();
    final modoEscuro = await _service.obterModoEscuro();
    final ultimoAcesso = await _service.obterUltimoAcesso();
    final tarefas = await _service.obterTarefas();

    // Registra o acesso atual para as próximas execuções
    await _service.salvarUltimoAcesso(DateTime.now().toString());

    if (!mounted) return;
    setState(() {
      _nomeController.text = nome;
      _modoEscuro = modoEscuro;
      _ultimoAcesso = ultimoAcesso;
      _tarefas = tarefas;
      _carregando = false;
    });
  }

  Future<void> _salvarPreferencias() async {
    await _service.salvarNomeUsuario(_nomeController.text);
    await _service.salvarModoEscuro(_modoEscuro);
    await _service.salvarTarefas(_tarefas);
    widget.onTemaAlterado(_modoEscuro);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências salvas com sucesso!')),
      );
    }
  }

  Future<void> _redefinirPadroes() async {
    await _service.limparTudo();
    if (!mounted) return;
    setState(() {
      _nomeController.text = 'Usuário Convidado';
      _modoEscuro = false;
      _ultimoAcesso = null;
      _tarefas = [];
    });
    widget.onTemaAlterado(false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências redefinidas com sucesso!')),
      );
    }
  }

  void _adicionarTarefa() {
    final texto = _novaTarefaController.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _tarefas.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'titulo': texto,
        'concluida': false,
      });
      _novaTarefaController.clear();
    });
    _service.salvarTarefas(_tarefas);
  }

  void _removerTarefa(int index) {
    setState(() {
      _tarefas.removeAt(index);
    });
    _service.salvarTarefas(_tarefas);
  }

  void _alternarTarefa(int index) {
    setState(() {
      _tarefas[index]['concluida'] = !(_tarefas[index]['concluida'] as bool);
    });
    _service.salvarTarefas(_tarefas);
  }

  String _formatarData(String? raw) {
    if (raw == null || raw.isEmpty) return 'Primeiro acesso ao aplicativo';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final dia = parsed.day.toString().padLeft(2, '0');
    final mes = parsed.month.toString().padLeft(2, '0');
    final ano = parsed.year;
    final hora = parsed.hour.toString().padLeft(2, '0');
    final min = parsed.minute.toString().padLeft(2, '0');
    final seg = parsed.second.toString().padLeft(2, '0');
    return '$dia/$mes/$ano às $hora:$min:$seg';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações & Perfil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ativar Modo Escuro'),
              subtitle: const Text('Persiste o tema visual selecionado no disco'),
              value: _modoEscuro,
              onChanged: (valor) => setState(() => _modoEscuro = valor),
            ),
            const Divider(height: 32),

            // Desafio Avançado: Armazenamento de Lista JSON em String
            Row(
              children: [
                const Icon(Icons.checklist, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tarefas Rápidas (Persistência JSON)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _novaTarefaController,
                    decoration: const InputDecoration(
                      hintText: 'Nova tarefa...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _adicionarTarefa(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _adicionarTarefa,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar Tarefa',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_tarefas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Nenhuma tarefa salva no momento.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tarefas.length,
                itemBuilder: (context, index) {
                  final item = _tarefas[index];
                  final concluida = item['concluida'] as bool? ?? false;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      leading: Checkbox(
                        value: concluida,
                        onChanged: (_) => _alternarTarefa(index),
                      ),
                      title: Text(
                        item['titulo']?.toString() ?? '',
                        style: TextStyle(
                          decoration: concluida
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _removerTarefa(index),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Botão Principal: Salvar Alterações
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarPreferencias,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
              ),
            ),
            const SizedBox(height: 12),

            // Desafio Intermediário: Resetar Padrões
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _redefinirPadroes,
                icon: const Icon(Icons.restore),
                label: const Text('Redefinir Padrões'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Desafio Básico: Data do Último Acesso no Rodapé
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Último acesso:',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatarData(_ultimoAcesso),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
