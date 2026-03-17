#!/usr/bin/env node

// Auditoria de formatos de hash no Firestore.
// Uso rapido:
// 1) npm init -y
// 2) npm install firebase-admin
// 3) Defina GOOGLE_APPLICATION_CREDENTIALS para um service account JSON
// 4) node scripts/auditoria_senha_hash_firestore.js
//
// Variaveis opcionais de ambiente:
// - FIRESTORE_COLLECTION (padrao: auditoria_credenciais)
// - HASH_FIELD (padrao: senha_hash)
// - PAGE_SIZE (padrao: 500)
// - OUTPUT_FILE (padrao: hash_audit_report.json)
// - FIREBASE_PROJECT_ID (opcional)

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const COLLECTION = process.env.FIRESTORE_COLLECTION || 'auditoria_credenciais';
const HASH_FIELD = process.env.HASH_FIELD || 'senha_hash';
const PAGE_SIZE = Number.parseInt(process.env.PAGE_SIZE || '500', 10);
const OUTPUT_FILE = process.env.OUTPUT_FILE || 'hash_audit_report.json';
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || undefined;

function inferirAlgoritmo(hash) {
	if (!hash || typeof hash !== 'string') {
		return 'ausente_ou_invalido';
	}

	const valor = hash.trim();

	if (/^\$2[aby]\$\d\d\$.{53}$/.test(valor)) {
		return 'bcrypt';
	}

	if (/^\$argon2(id|i|d)\$/.test(valor)) {
		return 'argon2';
	}

	if (/^pbkdf2_sha(1|224|256|384|512)\$/i.test(valor)) {
		return 'pbkdf2';
	}

	if (/^[a-f0-9]{32}$/i.test(valor)) {
		return 'md5_ou_hmac_md5';
	}

	if (/^[a-f0-9]{40}$/i.test(valor)) {
		return 'sha1_ou_ripemd160_ou_hmac_sha1';
	}

	if (/^[a-f0-9]{56}$/i.test(valor)) {
		return 'sha224_ou_hmac_sha224';
	}

	if (/^[a-f0-9]{64}$/i.test(valor)) {
		return 'sha256_ou_hmac_sha256';
	}

	if (/^[a-f0-9]{96}$/i.test(valor)) {
		return 'sha384_ou_hmac_sha384';
	}

	if (/^[a-f0-9]{128}$/i.test(valor)) {
		return 'sha512_ou_hmac_sha512';
	}

	return 'desconhecido';
}

function initFirestore() {
	if (!admin.apps.length) {
		const options = PROJECT_ID ? { projectId: PROJECT_ID } : undefined;
		admin.initializeApp(options);
	}
	return admin.firestore();
}

function addSample(samplesByBucket, bucket, docData) {
	if (!samplesByBucket[bucket]) {
		samplesByBucket[bucket] = [];
	}

	if (samplesByBucket[bucket].length >= 5) {
		return;
	}

	samplesByBucket[bucket].push(docData);
}

async function auditar() {
	const db = initFirestore();

	let total = 0;
	let semCampo = 0;
	let ultimoDoc = null;

	const contagem = {};
	const samples = {};

	while (true) {
		let query = db
			.collection(COLLECTION)
			.orderBy(admin.firestore.FieldPath.documentId())
			.limit(PAGE_SIZE);

		if (ultimoDoc) {
			query = query.startAfter(ultimoDoc.id);
		}

		const snap = await query.get();

		if (snap.empty) {
			break;
		}

		for (const doc of snap.docs) {
			total += 1;

			const data = doc.data() || {};
			const hash = data[HASH_FIELD];
			const bucket = inferirAlgoritmo(hash);

			if (!hash || typeof hash !== 'string' || hash.trim() === '') {
				semCampo += 1;
			}

			contagem[bucket] = (contagem[bucket] || 0) + 1;

			addSample(samples, bucket, {
				id: doc.id,
				hash: typeof hash === 'string' ? hash : null,
				tamanho: typeof hash === 'string' ? hash.length : null,
				origem: data.origem || null,
				criado_em: data.criado_em || null,
			});
		}

		ultimoDoc = snap.docs[snap.docs.length - 1];

		if (snap.size < PAGE_SIZE) {
			break;
		}
	}

	const resultado = {
		timestamp: new Date().toISOString(),
		collection: COLLECTION,
		field: HASH_FIELD,
		totalDocumentos: total,
		documentosSemHashValido: semCampo,
		distribuicao: contagem,
		amostras: samples,
	};

	const outputPath = path.resolve(process.cwd(), OUTPUT_FILE);
	fs.writeFileSync(outputPath, JSON.stringify(resultado, null, 2), 'utf8');

	console.log('--- Auditoria de Hashes ---');
	console.log('Collection:', COLLECTION);
	console.log('Campo:', HASH_FIELD);
	console.log('Total de documentos:', total);
	console.log('Sem hash valido:', semCampo);
	console.log('Distribuicao:');

	Object.keys(contagem)
		.sort((a, b) => contagem[b] - contagem[a])
		.forEach((bucket) => {
			console.log(`- ${bucket}: ${contagem[bucket]}`);
		});

	console.log('Relatorio salvo em:', outputPath);
}

auditar().catch((err) => {
	console.error('Falha na auditoria:', err.message);
	process.exitCode = 1;
});
