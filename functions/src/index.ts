import * as admin from "firebase-admin";
import {DocumentData, FieldValue, Timestamp} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";

admin.initializeApp();

const REGION = "southamerica-east1";
const SCHEDULE = "every 6 hours";
const TIME_ZONE = "America/Sao_Paulo";
const DEFAULT_INTERVAL_DAYS = 7;
const LAST_SENT_AT_FIELD = "mensagem_aleatoria_ultima_data";
const LAST_SENT_TEXT_FIELD = "mensagem_aleatoria_ultimo_texto";
const LAST_SENT_ORIGIN_FIELD = "mensagem_aleatoria_ultima_origem";
const NOTIFICATION_TITLE = "Agenda de Massoterapia";
const PREVIEW_LIMIT = 10;

setGlobalOptions({
  region: REGION,
  maxInstances: 10,
});

interface RandomMessagesConfig {
  mensagensAleatoriasAtivas: boolean;
  intervaloMensagensDias: number;
  usarNomePreferidoNasMensagens: boolean;
  enviarMensagensSemAgendamento: boolean;
  mensagensAleatoriasClientes: string[];
  indiceMensagemSelecionadaClientes: number;
}

interface DispatchOptions {
  dryRun: boolean;
  limite: number;
  origem: "agendador" | "manual";
  indiceMensagemSelecionada?: number | null;
}

interface MessagePreview {
  uid: string;
  nome: string;
  mensagem: string;
}

interface DispatchResult {
  origem: "agendador" | "manual";
  dryRun: boolean;
  totalClientes: number;
  elegiveis: number;
  enviados: number;
  simulados: number;
  ignoradosSemToken: number;
  ignoradosSemAgendamento: number;
  ignoradosIntervalo: number;
  ignoradosPorLimite: number;
  erros: number;
  limiteAplicado: number | null;
  modoSelecaoMensagem: "aleatoria" | "fixa";
  indiceMensagemSelecionada: number | null;
  exemplos: MessagePreview[];
}

const DEFAULT_MESSAGES = [
  "Oi {nome}, esperamos voce para sua proxima sessao. Seu bem-estar vem em primeiro lugar.",
  "Que tal reservar um horario esta semana para manter sua rotina de autocuidado?",
  "Lembrete de carinho: pausas e massagens regulares ajudam muito no equilibrio do corpo.",
];

function asTrimmedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function asBoolean(value: unknown, defaultValue = false): boolean {
  return typeof value === "boolean" ? value : defaultValue;
}

function asPositiveInt(value: unknown, defaultValue: number): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return defaultValue;
  }
  return Math.floor(parsed);
}

function asInt(value: unknown, defaultValue: number): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) {
    return defaultValue;
  }
  return Math.floor(parsed);
}

function normalizeSelectedMessageIndex(value: unknown, totalMessages: number): number {
  if (totalMessages <= 0) {
    return -1;
  }

  const index = asInt(value, -1);
  if (index < 0 || index >= totalMessages) {
    return -1;
  }

  return index;
}

function normalizeMessages(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => asTrimmedString(item))
    .filter((item) => item.length > 0);
}

function applyNamePlaceholder(template: string, nome: string): string {
  const nomeLimpo = nome.trim();
  const nomeSeguro = nomeLimpo.length === 0 ? "cliente" : nomeLimpo;
  return template
    .replace(/\{nome\}/gi, nomeSeguro)
    .replace(/\{name\}/gi, nomeSeguro);
}

function parseDate(value: unknown): Date | null {
  if (value instanceof Timestamp) {
    return value.toDate();
  }

  if (value instanceof Date) {
    return value;
  }

  if (typeof value === "string" || typeof value === "number") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }

  return null;
}

function intervalElapsed(lastSentValue: unknown, intervalDays: number, now: Date): boolean {
  const lastSent = parseDate(lastSentValue);
  if (!lastSent) {
    return true;
  }

  const elapsedMs = now.getTime() - lastSent.getTime();
  const requiredMs = intervalDays * 24 * 60 * 60 * 1000;
  return elapsedMs >= requiredMs;
}

function chooseRandom<T>(items: T[]): T {
  const index = Math.floor(Math.random() * items.length);
  return items[index];
}

function resolveClientName(
  userData: DocumentData,
  clienteData: DocumentData | null,
  usarNomePreferido: boolean,
): string {
  const preferidoUsuario = asTrimmedString(userData["nome_preferido"]);
  const preferidoCliente = asTrimmedString(clienteData?.["nome_preferido"]);
  const nomeUsuario = asTrimmedString(userData["nome_cliente"]) || asTrimmedString(userData["nome"]);
  const nomeCliente = asTrimmedString(clienteData?.["cliente_nome"]);

  if (usarNomePreferido) {
    return (
      preferidoUsuario ||
      preferidoCliente ||
      nomeUsuario ||
      nomeCliente ||
      "cliente"
    );
  }

  return (
    nomeUsuario ||
    nomeCliente ||
    preferidoUsuario ||
    preferidoCliente ||
    "cliente"
  );
}

async function loadRandomMessagesConfig(): Promise<RandomMessagesConfig> {
  const db = admin.firestore();
  const configDoc = await db.collection("configuracoes").doc("geral").get();
  const configData = configDoc.data() ?? {};

  const intervaloRaw =
    configData["mensagens_intervalo_dias"] ??
    configData["intervalo_mensagens_dias"];
  const usarNomeRaw =
    configData["mensagens_usar_nome_preferido"] ??
    configData["usar_nome_preferido_nas_mensagens"];
  const enviarSemAgendamentoRaw =
    configData["mensagens_enviar_sem_agendamento"] ??
    configData["enviar_mensagens_sem_agendamento"];
  const indiceSelecionadoRaw =
    configData["mensagens_indice_selecionada_clientes"] ??
    configData["mensagens_indice_mensagem_selecionada"];
  const mensagens = normalizeMessages(configData["mensagens_aleatorias_clientes"]);
  const mensagensNormalizadas = mensagens.length > 0 ? mensagens : DEFAULT_MESSAGES;

  return {
    mensagensAleatoriasAtivas: asBoolean(configData["mensagens_aleatorias_ativas"], false),
    intervaloMensagensDias: asPositiveInt(
      intervaloRaw,
      DEFAULT_INTERVAL_DAYS,
    ),
    usarNomePreferidoNasMensagens: asBoolean(usarNomeRaw, true),
    enviarMensagensSemAgendamento: asBoolean(enviarSemAgendamentoRaw, false),
    mensagensAleatoriasClientes: mensagensNormalizadas,
    indiceMensagemSelecionadaClientes: normalizeSelectedMessageIndex(
      indiceSelecionadoRaw,
      mensagensNormalizadas.length,
    ),
  };
}

async function loadClientsWithUpcomingAppointments(): Promise<Set<string>> {
  const db = admin.firestore();
  const nowTimestamp = Timestamp.now();

  const agendamentosSnap = await db
    .collection("agendamentos")
    .where("status", "==", "aprovado")
    .where("data_hora", ">", nowTimestamp)
    .select("cliente_id")
    .get();

  const clients = new Set<string>();
  for (const agendamentoDoc of agendamentosSnap.docs) {
    const clienteId = asTrimmedString(agendamentoDoc.get("cliente_id"));
    if (clienteId.length > 0) {
      clients.add(clienteId);
    }
  }
  return clients;
}

async function hasAdminOrDevAccess(uid: string): Promise<boolean> {
  const db = admin.firestore();
  const userDoc = await db.collection("usuarios").doc(uid).get();
  if (!userDoc.exists) {
    return false;
  }

  const userData = userDoc.data() ?? {};
  const tipo = asTrimmedString(userData["tipo"]).toLowerCase();
  const devMaster = asBoolean(userData["dev_master"]);
  const visualizaTodos = asBoolean(userData["visualiza_todos"]);
  return tipo === "admin" || devMaster || visualizaTodos;
}

async function dispatchRandomMessages(options: DispatchOptions): Promise<DispatchResult> {
  const db = admin.firestore();
  const now = new Date();
  const config = await loadRandomMessagesConfig();
  const indiceMensagemSelecionada = normalizeSelectedMessageIndex(
    options.indiceMensagemSelecionada == null
      ? config.indiceMensagemSelecionadaClientes
      : options.indiceMensagemSelecionada,
    config.mensagensAleatoriasClientes.length,
  );
  const usarMensagemSelecionada = indiceMensagemSelecionada >= 0;
  const mensagemSelecionada = usarMensagemSelecionada
    ? config.mensagensAleatoriasClientes[indiceMensagemSelecionada]
    : null;

  const result: DispatchResult = {
    origem: options.origem,
    dryRun: options.dryRun,
    totalClientes: 0,
    elegiveis: 0,
    enviados: 0,
    simulados: 0,
    ignoradosSemToken: 0,
    ignoradosSemAgendamento: 0,
    ignoradosIntervalo: 0,
    ignoradosPorLimite: 0,
    erros: 0,
    limiteAplicado: options.limite > 0 ? options.limite : null,
    modoSelecaoMensagem: usarMensagemSelecionada ? "fixa" : "aleatoria",
    indiceMensagemSelecionada: usarMensagemSelecionada ? indiceMensagemSelecionada : null,
    exemplos: [],
  };

  if (!config.mensagensAleatoriasAtivas) {
    logger.info("Rotina ignorada: mensagens aleatorias desativadas.");
    return result;
  }

  const usuariosSnap = await db
    .collection("usuarios")
    .where("tipo", "==", "cliente")
    .where("aprovado", "==", true)
    .get();

  result.totalClientes = usuariosSnap.size;

  let clientsWithUpcoming = new Set<string>();
  if (!config.enviarMensagensSemAgendamento) {
    clientsWithUpcoming = await loadClientsWithUpcomingAppointments();
  }

  let processedByLimit = 0;
  const clientCache = new Map<string, DocumentData | null>();

  for (const usuarioDoc of usuariosSnap.docs) {
    const uid = usuarioDoc.id;
    const userData = usuarioDoc.data();
    const token = asTrimmedString(userData["fcm_token"]);

    if (token.length === 0) {
      result.ignoradosSemToken += 1;
      continue;
    }

    if (!config.enviarMensagensSemAgendamento && !clientsWithUpcoming.has(uid)) {
      result.ignoradosSemAgendamento += 1;
      continue;
    }

    if (!intervalElapsed(userData[LAST_SENT_AT_FIELD], config.intervaloMensagensDias, now)) {
      result.ignoradosIntervalo += 1;
      continue;
    }

    result.elegiveis += 1;

    if (options.limite > 0 && processedByLimit >= options.limite) {
      result.ignoradosPorLimite += 1;
      continue;
    }

    processedByLimit += 1;

    try {
      let clienteData: DocumentData | null = null;
      if (clientCache.has(uid)) {
        clienteData = clientCache.get(uid) ?? null;
      } else {
        const clienteDoc = await db.collection("clientes").doc(uid).get();
        clienteData = clienteDoc.exists ? (clienteDoc.data() ?? null) : null;
        clientCache.set(uid, clienteData);
      }

      const nome = resolveClientName(
        userData,
        clienteData,
        config.usarNomePreferidoNasMensagens,
      );
      const template = mensagemSelecionada ?? chooseRandom(config.mensagensAleatoriasClientes);
      const mensagem = applyNamePlaceholder(template, nome);

      if (options.dryRun) {
        result.simulados += 1;
        if (result.exemplos.length < PREVIEW_LIMIT) {
          result.exemplos.push({uid, nome, mensagem});
        }
        continue;
      }

      await admin.messaging().send({
        token,
        notification: {
          title: NOTIFICATION_TITLE,
          body: mensagem,
        },
        data: {
          tipo: "mensagem_aleatoria",
          origem: options.origem,
        },
        android: {priority: "high"},
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      await db.collection("usuarios").doc(uid).set(
        {
          [LAST_SENT_AT_FIELD]: FieldValue.serverTimestamp(),
          [LAST_SENT_TEXT_FIELD]: mensagem,
          [LAST_SENT_ORIGIN_FIELD]: options.origem,
        },
        {merge: true},
      );

      await db.collection("clientes").doc(uid).set(
        {
          [LAST_SENT_AT_FIELD]: FieldValue.serverTimestamp(),
          [LAST_SENT_TEXT_FIELD]: mensagem,
          [LAST_SENT_ORIGIN_FIELD]: options.origem,
        },
        {merge: true},
      );

      result.enviados += 1;
    } catch (error) {
      result.erros += 1;
      logger.error("Falha ao enviar mensagem aleatoria", {
        uid,
        error,
      });
    }
  }

  await db.collection("logs").add({
    tipo: "mensagens_aleatorias",
    origem: options.origem,
    resultado: result,
    criado_em: FieldValue.serverTimestamp(),
  });

  return result;
}

export const rotinaMensagensAleatoriasClientes = onSchedule(
  {
    schedule: SCHEDULE,
    timeZone: TIME_ZONE,
    retryCount: 2,
    maxRetrySeconds: 3600,
  },
  async () => {
    const result = await dispatchRandomMessages({
      dryRun: false,
      limite: 0,
      origem: "agendador",
    });

    logger.info("Rotina de mensagens aleatorias finalizada", result);
  },
);

export const dispararMensagensAleatoriasClientesManual = onCall(
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError(
        "unauthenticated",
        "Usuario nao autenticado para disparo manual.",
      );
    }

    const hasAccess = await hasAdminOrDevAccess(request.auth.uid);
    if (!hasAccess) {
      throw new HttpsError(
        "permission-denied",
        "Sem permissao para disparar mensagens aleatorias.",
      );
    }

    const payload = (request.data ?? {}) as Record<string, unknown>;
    const dryRun = payload["dryRun"] === true;
    const limite = Math.max(
      0,
      Math.min(asPositiveInt(payload["limite"], 0), 5000),
    );
    const indiceMensagemSelecionada = payload["indiceMensagemSelecionada"] == null
      ? null
      : asInt(payload["indiceMensagemSelecionada"], -1);

    const result = await dispatchRandomMessages({
      dryRun,
      limite,
      origem: "manual",
      indiceMensagemSelecionada,
    });

    logger.info("Disparo manual de mensagens aleatorias finalizado", {
      requestedBy: request.auth.uid,
      ...result,
    });

    return result;
  },
);
