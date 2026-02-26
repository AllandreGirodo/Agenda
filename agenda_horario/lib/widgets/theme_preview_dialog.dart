import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/custom_theme_data.dart';
import 'animated_background.dart';

class ThemePreviewDialog extends StatefulWidget {
  const ThemePreviewDialog({super.key});

  @override
  State<ThemePreviewDialog> createState() => _ThemePreviewDialogState();
}

class _ThemePreviewDialogState extends State<ThemePreviewDialog> {
  AppThemeType _selectedTheme = AppThemeType.sistema;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escolher Tema'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Área de Pré-visualização
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Fundo Animado Selecionado
                    AnimatedBackground(
                      themeType: _selectedTheme,
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Pré-visualização'),
                          ),
                        ),
                      ),
                    ),
                    // Etiqueta
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.black54,
                        child: Text(
                          CustomThemeData.getData(_selectedTheme).label,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Dropdown de Seleção
            DropdownButtonFormField<AppThemeType>(
              value: _selectedTheme,
              decoration: const InputDecoration(
                labelText: 'Selecione um tema',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: AppThemeType.values.map((type) {
                final data = CustomThemeData.getData(type);
                return DropdownMenuItem(
                  value: type,
                  enabled: data.isAvailable,
                  child: Text(
                    data.label + (data.isAvailable ? '' : ' (Bloqueado)'),
                    style: TextStyle(color: data.isAvailable ? null : Colors.grey),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedTheme = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            MyApp.setCustomTheme(context, _selectedTheme);
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}