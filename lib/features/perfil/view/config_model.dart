import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ConfigModel {
  final Map<String, bool> camposObrigatorios;
  final int inicioSono;
  final int fimSono;
  final double horasAntecedenciaCancelamento;

  ConfigModel({
    required this.camposObrigatorios,
    required this.inicioSono,
    required this.fimSono,
    required this.horasAntecedenciaCancelamento,
  });

  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    return ConfigModel(
      camposObrigatorios: Map<String, bool>.from(map['campos_obrigatorios'] ?? {}),
      inicioSono: map['inicio_sono'] ?? 22,
      fimSono: map['fim_sono'] ?? 6,
      horasAntecedenciaCancelamento: (map['horas_antecedencia_cancelamento'] ?? 24).toDouble(),
    );
  }

  // Adicionando factory vazio para evitar erros se for chamado em outros lugares
  factory ConfigModel.empty() {
    return ConfigModel(camposObrigatorios: {}, inicioSono: 0, fimSono: 0, horasAntecedenciaCancelamento: 0);
  }
}