#!/usr/bin/env node

// Migra dados da colecao legada `clientes/{uid}` para
// `usuarios/{email_normalizado}/perfil/cliente` e opcionalmente remove legado.
//
// Seguranca por padrao:
// - DRY-RUN habilitado (nao escreve nada).
// - Remocao de legado so ocorre com --delete-legacy.
//
// Uso:
//   node scripts/migrar_clientes_legado.js
//   node scripts/migrar_clientes_legado.js --apply
//   node scripts/migrar_clientes_legado.js --apply --delete-legacy
//   node scripts/migrar_clientes_legado.js --apply --uid=abc123
//   node scripts/migrar_clientes_legado.js --apply --limit=100
//
// Opcoes:
//   --apply              Executa escrita no Firestore (sem isso: dry-run)
//   --delete-legacy      Remove clientes/{uid} apos migracao valida
//   --uid=<uid>          Migra somente um UID
//   --limit=<n>          Limita quantidade de docs da colecao legada
//   --report=<arquivo>   Caminho do relatorio JSON (padrao: migration_clientes_report.json)
//   --project=<id>       Forca projectId no initializeApp

const fs = require('fs');
const path = require('path');

function parseArgs(argv) {
  const args = {
    apply: false,
    deleteLegacy: false,
    uid: '',
    limit: 0,
    report: 'migration_clientes_report.json',
    projectId: '',
  };

  for (const raw of argv) {
    const arg = String(raw || '').trim();
    if (arg === '--apply') args.apply = true;
    if (arg === '--delete-legacy') args.deleteLegacy = true;
    if (arg.startsWith('--uid=')) args.uid = arg.slice('--uid='.length).trim();
    if (arg.startsWith('--limit=')) {
      const n = Number.parseInt(arg.slice('--limit='.length).trim(), 10);
      if (Number.isFinite(n) && n > 0) args.limit = n;
    }
    if (arg.startsWith('--report=')) {
      const value = arg.slice('--report='.length).trim();
      if (value) args.report = value;
    }
    if (arg.startsWith('--project=')) {
      const value = arg.slice('--project='.length).trim();
      if (value) args.projectId = value;
    }
  }

  return args;
}

function loadFirebaseAdmin() {
  try {
    return require('firebase-admin');
  } catch (_) {
    const localPath = path.resolve(__dirname, '../functions/node_modules/firebase-admin');
    return require(localPath);
  }
}

function normalizePhone(phone) {
  return String(phone || '').replace(/[^0-9]/g, '');
}

function normalizeDayKey(key) {
  const map = {
    domingo: '1_domingo',
    segunda_feira: '2_segunda',
    terca_feira: '3_terca',
    quarta_feira: '4_quarta',
    quinta_feira: '5_quinta',
    sexta_feira: '6_sexta',
    sabado: '7_sabado',
    '1_domingo': '1_domingo',
    '2_segunda': '2_segunda',
    '3_terca': '3_terca',
    '4_quarta': '4_quarta',
    '5_quinta': '5_quinta',
    '6_sexta': '6_sexta',
    '7_sabado': '7_sabado',
  };

  const normalized = String(key || '').trim().toLowerCase();
  return map[normalized] || '';
}

function defaultAgendaFixa() {
  return {
    '1_domingo': false,
    '2_segunda': false,
    '3_terca': false,
    '4_quarta': false,
    '5_quinta': false,
    '6_sexta': false,
    '7_sabado': false,
  };
}

function normalizeAgendaFixaSemana(raw) {
  const target = defaultAgendaFixa();
  if (!raw || typeof raw !== 'object') return target;

  for (const [key, value] of Object.entries(raw)) {
    const day = normalizeDayKey(key);
    if (!day) continue;
    target[day] = value === true || value === 1 || String(value).toLowerCase() === 'true';
  }

  return target;
}

function normalizeUltimoDiaSemana(value) {
  const day = normalizeDayKey(value);
  return day || String(value || '').trim();
}

function sanitizeLegacyToProfile(uid, legacy) {
  const nome = String(legacy.cliente_nome || legacy.nome || '').trim();
  const nomeFinal = nome || 'Cliente';

  const telefonePrincipal = normalizePhone(
    legacy.telefone_principal || legacy.whatsapp || '',
  );

  const agendaFixaSemana = normalizeAgendaFixaSemana(legacy.agenda_fixa_semana);

  const merged = {
    uid,
    cliente_nome: nomeFinal,
    nome: nomeFinal,
    nome_preferido: String(legacy.nome_preferido || '').trim(),
    ddi: String(legacy.ddi || '55').trim() || '55',
    whatsapp: telefonePrincipal,
    telefone_principal: telefonePrincipal,
    nome_contato_secundario: String(legacy.nome_contato_secundario || '').trim(),
    telefone_secundario: normalizePhone(legacy.telefone_secundario || ''),
    nome_indicacao: String(legacy.nome_indicacao || '').trim(),
    telefone_indicacao: normalizePhone(legacy.telefone_indicacao || ''),
    categoria_origem: String(legacy.categoria_origem || '').trim(),
    presenca_agenda: legacy.presenca_agenda === true,
    frequencia_historica_agenda: Number(legacy.frequencia_historica_agenda || 0),
    ultima_data_agendada: legacy.ultima_data_agendada || null,
    ultimo_horario_agendado: String(legacy.ultimo_horario_agendado || '').trim(),
    ultimo_dia_semana_agendado: normalizeUltimoDiaSemana(legacy.ultimo_dia_semana_agendado),
    sugestao_cliente_fixo: legacy.sugestao_cliente_fixo === true,
    agenda_fixa_semana: agendaFixaSemana,
    agenda_historico:
      legacy.agenda_historico && typeof legacy.agenda_historico === 'object'
        ? legacy.agenda_historico
        : {
            horarios_recorrentes: '',
            outro_horario_1: '',
            outro_horario_2: '',
            outro_horario_3: '',
            outro_horario_4: '',
            outro_horario_5: '',
          },
    cpf: String(legacy.cpf || '').trim(),
    cep: String(legacy.cep || '').trim(),
    data_nascimento: legacy.data_nascimento || null,
    saldo_sessoes: Number(legacy.saldo_sessoes || 0),
    favoritos: Array.isArray(legacy.favoritos) ? legacy.favoritos : [],
    endereco: String(legacy.endereco || '').trim(),
    historico_medico: String(legacy.historico_medico || '').trim(),
    alergias: String(legacy.alergias || '').trim(),
    medicamentos: String(legacy.medicamentos || '').trim(),
    cirurgias: String(legacy.cirurgias || '').trim(),
    anamnese_ok: legacy.anamnese_ok === true,
    migracao_legado: {
      origem: 'clientes',
      migrado_em: new Date().toISOString(),
      script: 'scripts/migrar_clientes_legado.js',
    },
  };

  return merged;
}

async function run() {
  const args = parseArgs(process.argv.slice(2));
  const dryRun = !args.apply;
  const admin = loadFirebaseAdmin();

  if (!admin.apps.length) {
    const options = args.projectId ? { projectId: args.projectId } : undefined;
    admin.initializeApp(options);
  }

  const db = admin.firestore();

  let query = db.collection('clientes');
  if (args.uid) {
    query = query.where(admin.firestore.FieldPath.documentId(), '==', args.uid);
  }
  if (args.limit > 0) {
    query = query.limit(args.limit);
  }

  const snap = await query.get();

  const stats = {
    timestamp: new Date().toISOString(),
    dryRun,
    deleteLegacy: args.deleteLegacy,
    totalLegacyLidos: snap.size,
    semUsuarioDestino: 0,
    elegiveisMigracao: 0,
    migrados: 0,
    removidosLegado: 0,
    falhas: 0,
  };

  const detalhes = [];

  for (const doc of snap.docs) {
    const uid = doc.id;
    const legacy = doc.data() || {};

    try {
      const usuarioByUid = await db
        .collection('usuarios')
        .where('id', '==', uid)
        .limit(1)
        .get();

      if (usuarioByUid.empty) {
        stats.semUsuarioDestino += 1;
        detalhes.push({
          uid,
          status: 'ignorado_sem_usuario_destino',
        });
        continue;
      }

      const usuarioDoc = usuarioByUid.docs[0];
      const usuarioData = usuarioDoc.data() || {};
      const emailNormalizado = String(
        usuarioData.email_normalizado || usuarioDoc.id || '',
      )
        .trim()
        .toLowerCase();

      if (!emailNormalizado) {
        stats.semUsuarioDestino += 1;
        detalhes.push({
          uid,
          status: 'ignorado_email_normalizado_vazio',
        });
        continue;
      }

      const perfilRef = db
        .collection('usuarios')
        .doc(emailNormalizado)
        .collection('perfil')
        .doc('cliente');

      const payload = sanitizeLegacyToProfile(uid, legacy);

      stats.elegiveisMigracao += 1;

      if (!dryRun) {
        await perfilRef.set(payload, { merge: true });
        stats.migrados += 1;

        if (args.deleteLegacy) {
          await doc.ref.delete();
          stats.removidosLegado += 1;
        }
      }

      detalhes.push({
        uid,
        emailNormalizado,
        status: dryRun ? 'simulado' : 'migrado',
        deleteLegacy: !dryRun && args.deleteLegacy,
      });
    } catch (error) {
      stats.falhas += 1;
      detalhes.push({
        uid,
        status: 'erro',
        erro: String(error && error.message ? error.message : error),
      });
    }
  }

  const report = {
    stats,
    detalhes,
  };

  const reportPath = path.resolve(process.cwd(), args.report);
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2), 'utf8');

  console.log('--- Migracao clientes legado -> usuarios/*/perfil/cliente ---');
  console.log('dryRun:', dryRun);
  console.log('deleteLegacy:', args.deleteLegacy);
  console.log('totalLegacyLidos:', stats.totalLegacyLidos);
  console.log('semUsuarioDestino:', stats.semUsuarioDestino);
  console.log('elegiveisMigracao:', stats.elegiveisMigracao);
  console.log('migrados:', stats.migrados);
  console.log('removidosLegado:', stats.removidosLegado);
  console.log('falhas:', stats.falhas);
  console.log('relatorio:', reportPath);
}

run().catch((err) => {
  console.error('Falha na migracao:', err && err.message ? err.message : err);
  process.exitCode = 1;
});
