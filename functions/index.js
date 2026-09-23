const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

initializeApp();

async function assertRole(uid, allowed) {
  const snap = await getFirestore().collection("users").doc(uid).get();
  const role = snap.data()?.role;
  if (!allowed.includes(role)) {
    throw new HttpsError("permission-denied", "Not authorized.");
  }
}

exports.setRoleClaim = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  await assertRole(request.auth.uid, ["admin"]);
  const {uid, role} = request.data || {};
  if (!uid || !["public", "worker", "official", "admin"].includes(role)) {
    throw new HttpsError("invalid-argument", "Invalid role payload.");
  }
  await getAuth().setCustomUserClaims(uid, {role});
  return {ok: true};
});

exports.sendActivationEmail = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  await assertRole(request.auth.uid, ["admin", "official"]);
  const email = request.data?.email;
  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required.");
  }
  const link = await getAuth().generatePasswordResetLink(email);
  await getFirestore().collection("mail").add({
    to: [email],
    message: {
      subject: "HamroFix account approved",
      text:
        "Your HamroFix account has been approved. Set your password using this link: " +
        link,
    },
    createdAt: FieldValue.serverTimestamp(),
  });
  return {ok: true, delivery: "queued_if_trigger_email_extension_enabled"};
});
