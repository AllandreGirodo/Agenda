import 'package:agenda/features/admin/view/config_view.dart';
import 'package:agenda/features/agendamento/view/admin_agendamentos_view.dart';
import 'package:agenda/view/dev_tools_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const widths = <double>[320, 375, 414, 768, 1024];

  group('Breakpoints responsivos', () {
    test('AdminConfigView alterna layout compacto corretamente', () {
      final expected = <bool>[true, true, true, false, false];

      for (var i = 0; i < widths.length; i++) {
        expect(
          AdminConfigView.isCompactLayoutForWidth(widths[i]),
          expected[i],
          reason: 'width=${widths[i]}',
        );
      }
    });

    test('DevToolsView alterna layout compacto por largura', () {
      final expected = <bool>[true, true, true, true, false];

      for (var i = 0; i < widths.length; i++) {
        expect(
          DevToolsView.isCompactLayoutForWidth(widths[i]),
          expected[i],
          reason: 'width=${widths[i]}',
        );
      }
    });

    test('DevToolsView modo compacto forca layout compacto', () {
      for (final width in widths) {
        expect(
          DevToolsView.isCompactLayoutForWidth(width, modoCompacto: true),
          isTrue,
          reason: 'width=$width',
        );
      }
    });

    test('AdminAgendamentosView alterna layout compacto corretamente', () {
      final expected = <bool>[true, true, true, true, false];

      for (var i = 0; i < widths.length; i++) {
        expect(
          AdminAgendamentosView.isCompactLayoutForWidth(widths[i]),
          expected[i],
          reason: 'width=${widths[i]}',
        );
      }
    });
  });
}
