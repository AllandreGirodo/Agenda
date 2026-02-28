const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// RF008: Retenção e Descarte Automático
// Executa todos os dias à meia-noite para limpar logs com mais de 5 anos
exports.limparLogsLgpdAntigos = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
  const now = new Date();
  // Subtrai 5 anos da data atual
  const fiveYearsAgo = new Date(now.setFullYear(now.getFullYear() - 5));
  const cutoff = admin.firestore.Timestamp.fromDate(fiveYearsAgo);

  // Busca logs antigos
  const snapshot = await admin.firestore().collection("lgpd_logs")
      .where("data_hora", "<", cutoff)
      .get();

  if (snapshot.empty) {
    return null;
  }

  // Deleta em lote (Batch)
  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Logs LGPD antigos excluídos: ${snapshot.size}`);
  return null;
});