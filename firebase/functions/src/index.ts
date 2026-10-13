import { randomInt } from "node:crypto";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getStorage } from "firebase-admin/storage";
import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";

initializeApp();
// Misma región que la base de Firestore (los triggers deben estar en la región de la base).
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

const db = getFirestore();

const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // sin 0/O/1/I para evitar confusiones
const CODE_LENGTH = 6;
const INVITE_TTL_MS = 48 * 60 * 60 * 1000;

function randomCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  }
  return code;
}

function requireUid(auth: { uid: string } | undefined): string {
  if (!auth?.uid) throw new HttpsError("unauthenticated", "Inicia sesión primero.");
  return auth.uid;
}

// ---------------------------------------------------------------------------
// Notificaciones
// ---------------------------------------------------------------------------

async function sendToUser(
  uid: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<void> {
  const userRef = db.doc(`users/${uid}`);
  const snap = await userRef.get();
  const tokens: string[] = snap.get("fcmTokens") ?? [];
  if (tokens.length === 0) {
    logger.info(`El usuario ${uid} no tiene tokens FCM; no se envía notificación.`);
    return;
  }

  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    apns: { payload: { aps: { sound: "default", badge: 1 } } },
  });

  const invalid: string[] = [];
  res.responses.forEach((r, i) => {
    const code = r.error?.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token" ||
      code === "messaging/invalid-argument"
    ) {
      invalid.push(tokens[i]);
    } else if (r.error) {
      logger.warn("Error enviando notificación", r.error);
    }
  });
  if (invalid.length > 0) {
    await userRef.update({ fcmTokens: FieldValue.arrayRemove(...invalid) });
  }
}

async function partnerOf(coupleId: string, uid: string): Promise<string | undefined> {
  const couple = await db.doc(`couples/${coupleId}`).get();
  const members: string[] = couple.get("members") ?? [];
  return members.find((m) => m !== uid);
}

async function displayName(uid: string): Promise<string> {
  const snap = await db.doc(`users/${uid}`).get();
  return (snap.get("displayName") as string | undefined) ?? "Tu pareja";
}

// ---------------------------------------------------------------------------
// Vinculación de pareja
// ---------------------------------------------------------------------------

/** Genera un código de 6 caracteres que la pareja escribe para vincularse. */
export const createInvite = onCall(async (req) => {
  const uid = requireUid(req.auth);
  const userRef = db.doc(`users/${uid}`);
  const user = (await userRef.get()).data() ?? {};

  if (user.coupleId) {
    throw new HttpsError("failed-precondition", "Ya tienes una pareja vinculada.");
  }
  if (user.inviteCode) {
    await db.doc(`invites/${user.inviteCode}`).delete().catch(() => undefined);
  }

  for (let attempt = 0; attempt < 5; attempt++) {
    const code = randomCode();
    try {
      await db.doc(`invites/${code}`).create({
        ownerUid: uid,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + INVITE_TTL_MS),
      });
      await userRef.set({ inviteCode: code }, { merge: true });
      return { code };
    } catch {
      // El código ya existía; probamos otro.
    }
  }
  throw new HttpsError("internal", "No se pudo generar el código. Intenta de nuevo.");
});

/** La pareja escribe el código y quedan vinculados. */
export const joinCouple = onCall<{ code?: string }>(async (req) => {
  const uid = requireUid(req.auth);
  const code = String(req.data?.code ?? "").trim().toUpperCase();
  if (code.length !== CODE_LENGTH) {
    throw new HttpsError("invalid-argument", "El código debe tener 6 caracteres.");
  }

  const coupleRef = db.collection("couples").doc();
  let ownerUid = "";

  await db.runTransaction(async (tx) => {
    const inviteRef = db.doc(`invites/${code}`);
    const invite = await tx.get(inviteRef);
    if (!invite.exists) throw new HttpsError("not-found", "Código no válido.");

    ownerUid = invite.get("ownerUid");
    const expiresAt = invite.get("expiresAt") as Timestamp;
    if (expiresAt.toMillis() < Date.now()) {
      throw new HttpsError("deadline-exceeded", "El código expiró. Pide uno nuevo.");
    }
    if (ownerUid === uid) {
      throw new HttpsError("failed-precondition", "No puedes usar tu propio código.");
    }

    const ownerRef = db.doc(`users/${ownerUid}`);
    const meRef = db.doc(`users/${uid}`);
    const [ownerSnap, meSnap] = await Promise.all([tx.get(ownerRef), tx.get(meRef)]);
    if (ownerSnap.get("coupleId")) {
      throw new HttpsError("failed-precondition", "Esa persona ya tiene pareja vinculada.");
    }
    if (meSnap.get("coupleId")) {
      throw new HttpsError("failed-precondition", "Ya tienes una pareja vinculada.");
    }

    tx.set(coupleRef, {
      members: [ownerUid, uid],
      createdAt: FieldValue.serverTimestamp(),
      active: true,
    });
    tx.set(ownerRef, { coupleId: coupleRef.id, partnerUid: uid, inviteCode: FieldValue.delete() }, { merge: true });
    tx.set(meRef, { coupleId: coupleRef.id, partnerUid: ownerUid, inviteCode: FieldValue.delete() }, { merge: true });
    tx.delete(inviteRef);

    const myOwnInvite = meSnap.get("inviteCode") as string | undefined;
    if (myOwnInvite) tx.delete(db.doc(`invites/${myOwnInvite}`));
  });

  const name = await displayName(uid);
  await sendToUser(ownerUid, "💞 ¡Ya están vinculados!", `${name} se unió a tu GF Tracker.`, {
    type: "linked",
  }).catch((e) => logger.warn(e));

  return { coupleId: coupleRef.id };
});

/** Desvincula a la pareja. Los datos se conservan pero ya nadie puede verlos. */
export const unlinkCouple = onCall(async (req) => {
  const uid = requireUid(req.auth);
  const me = await db.doc(`users/${uid}`).get();
  const coupleId = me.get("coupleId") as string | undefined;
  if (!coupleId) throw new HttpsError("failed-precondition", "No tienes pareja vinculada.");

  const coupleRef = db.doc(`couples/${coupleId}`);
  const members: string[] = (await coupleRef.get()).get("members") ?? [uid];

  const batch = db.batch();
  for (const member of members) {
    batch.set(
      db.doc(`users/${member}`),
      { coupleId: FieldValue.delete(), partnerUid: FieldValue.delete() },
      { merge: true },
    );
  }
  batch.set(coupleRef, { active: false, unlinkedAt: FieldValue.serverTimestamp() }, { merge: true });
  await batch.commit();
  return { ok: true };
});

// ---------------------------------------------------------------------------
// Triggers: contadores + notificación a la pareja
// ---------------------------------------------------------------------------

export const onEntryCreated = onDocumentCreated(
  "couples/{coupleId}/categories/{categoryId}/entries/{entryId}",
  async (event) => {
    const entry = event.data?.data();
    if (!entry) return;
    const { coupleId, categoryId, entryId } = event.params;
    const categoryRef = db.doc(`couples/${coupleId}/categories/${categoryId}`);

    await categoryRef.update({
      entryCount: FieldValue.increment(1),
      lastEntryAt: entry.createdAt ?? FieldValue.serverTimestamp(),
    });

    const author = entry.createdBy as string;
    const [partnerUid, category, name] = await Promise.all([
      partnerOf(coupleId, author),
      categoryRef.get(),
      displayName(author),
    ]);
    if (!partnerUid) return;

    const emoji = (category.get("emoji") as string | undefined) ?? "✨";
    const catName = (category.get("name") as string | undefined) ?? "algo";
    const total = (category.get("entryCount") as number | undefined) ?? 0;
    const note = ((entry.note as string | undefined) ?? "").trim();

    await sendToUser(
      partnerUid,
      `${emoji} ${name} registró: ${catName}`,
      note.length > 0 ? `${note} · lleva ${total}` : `Ya lleva ${total} en total`,
      { type: "entry", coupleId, categoryId, entryId },
    );
  },
);

export const onCategoryCreated = onDocumentCreated(
  "couples/{coupleId}/categories/{categoryId}",
  async (event) => {
    const category = event.data?.data();
    if (!category) return;
    const { coupleId, categoryId } = event.params;
    const owner = category.ownerUid as string;
    const [partnerUid, name] = await Promise.all([partnerOf(coupleId, owner), displayName(owner)]);
    if (!partnerUid) return;

    await sendToUser(
      partnerUid,
      `${category.emoji ?? "📂"} Nueva categoría`,
      `${name} empezó a registrar: ${category.name}`,
      { type: "category", coupleId, categoryId },
    );
  },
);

export const onEntryDeleted = onDocumentDeleted(
  "couples/{coupleId}/categories/{categoryId}/entries/{entryId}",
  async (event) => {
    const { coupleId, categoryId, entryId } = event.params;
    await db
      .doc(`couples/${coupleId}/categories/${categoryId}`)
      .update({ entryCount: FieldValue.increment(-1) })
      .catch(() => undefined); // la categoría pudo haberse borrado
    await getStorage()
      .bucket()
      .file(`couples/${coupleId}/categories/${categoryId}/entries/${entryId}.jpg`)
      .delete({ ignoreNotFound: true })
      .catch((e) => logger.warn(e));
  },
);

export const onCategoryDeleted = onDocumentDeleted(
  "couples/{coupleId}/categories/{categoryId}",
  async (event) => {
    const { coupleId, categoryId } = event.params;
    const categoryRef = db.doc(`couples/${coupleId}/categories/${categoryId}`);
    await db.recursiveDelete(categoryRef.collection("entries"));
    await getStorage()
      .bucket()
      .deleteFiles({ prefix: `couples/${coupleId}/categories/${categoryId}/` })
      .catch((e) => logger.warn(e));
  },
);
