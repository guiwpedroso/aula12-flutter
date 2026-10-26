import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdm_aula12_shared_preferences/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Carrega tela de configuracoes com sucesso', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'key_nome_usuario': 'Aluno Teste',
      'key_modo_escuro': false,
    });

    await tester.pumpWidget(const MeuApp(modoEscuroInicial: false));
    await tester.pumpAndSettle();

    expect(find.text('Configurações & Perfil'), findsOneWidget);
    expect(find.text('Aluno Teste'), findsOneWidget);
    expect(find.text('Salvar Alterações'), findsOneWidget);
  });
}
