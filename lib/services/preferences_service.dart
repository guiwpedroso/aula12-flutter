import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyNomeUsuario = 'key_nome_usuario';
  static const String _keyModoEscuro = 'key_modo_escuro';
  static const String _keyUltimoAcesso = 'key_ultimo_acesso';
  static const String _keyTarefas = 'key_tarefas';

  Future<void> salvarNomeUsuario(String nome) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNomeUsuario, nome);
  }

  Future<String> obterNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNomeUsuario) ?? 'Usuário Convidado';
  }

  Future<void> salvarModoEscuro(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyModoEscuro, valor);
  }

  Future<bool> obterModoEscuro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyModoEscuro) ?? false;
  }

  Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- Desafios de Persistência ---

  // Desafio Básico: Data do Último Acesso
  Future<void> salvarUltimoAcesso([String? dataHora]) async {
    final prefs = await SharedPreferences.getInstance();
    final valor = dataHora ?? DateTime.now().toString();
    await prefs.setString(_keyUltimoAcesso, valor);
  }

  Future<String?> obterUltimoAcesso() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUltimoAcesso);
  }

  // Desafio Avançado: Armazenamento de Lista JSON em String
  Future<void> salvarTarefas(List<Map<String, dynamic>> tarefas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTarefas, jsonEncode(tarefas));
  }

  Future<List<Map<String, dynamic>>> obterTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyTarefas);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
