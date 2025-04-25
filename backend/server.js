require('dotenv').config();
const express = require('express');
const admin = require('firebase-admin');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const cors = require('cors');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');

const app = express();
const storage = multer.memoryStorage();
const upload = multer({ storage });

app.use(express.json());
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Firebase Admin SDK Initialization
try {
  const serviceAccount = require('./ballouchi-23808-firebase-adminsdk-fbsvc-855195d4de.json');

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: serviceAccount.project_id,
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key.replace(/\\n/g, '\n'),
    }),
    databaseURL: 'https://ballouchi-23808.firebaseio.com',
    storageBucket: 'ballouchi-23808.appspot.com',
  });

  console.log("Firebase Admin initialized successfully");
} catch (error) {
  console.error("Firebase Admin initialization error:", error);
  process.exit(1);
}

const db = admin.firestore();
const auth = admin.auth();
const bucket = admin.storage().bucket();

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

function generateVerificationCode() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// Test Firebase endpoint
app.get('/api/test-firebase', async (req, res) => {
  try {
    const testRef = db.collection('testConnection').doc('testDoc');
    await testRef.set({ timestamp: admin.firestore.FieldValue.serverTimestamp() });
    const doc = await testRef.get();
    await auth.listUsers(1);

    res.json({ status: 'success', firestore: 'working', auth: 'working', testDocument: doc.data() });
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Firebase connection failed', error: error.message });
  }
});

// Sign up route
app.post('/api/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'Tous les champs sont requis' });
    }

    const userRef = db.collection('users').doc(email);
    const userDoc = await userRef.get();
    if (userDoc.exists) {
      return res.status(400).json({ message: 'Email déjà utilisé' });
    }

    await auth.createUser({ email, password, displayName: username });

    const verificationCode = generateVerificationCode();
    const verificationCodeExpires = Date.now() + 900000;
    const hashedPassword = await bcrypt.hash(password, 10);

    await userRef.set({
      email,
      username,
      password: hashedPassword,
      isVerified: false,
      verificationCode,
      verificationCodeExpires,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Code de Vérification Ballouchi',
      html: `<h2>Bienvenue sur Ballouchi!</h2><p>Votre code de vérification est : <strong>${verificationCode}</strong></p><p>Ce code expirera dans 15 minutes.</p>`
    };
    await transporter.sendMail(mailOptions);

    res.status(201).json({ message: 'Code de vérification envoyé avec succès', email });
  } catch (error) {
    res.status(500).json({ message: 'Erreur du serveur', error: error.message });
  }
});

// Verify code route
app.post('/api/verify', async (req, res) => {
  try {
    const { email, code } = req.body;
    const userRef = db.collection('users').doc(email);
    const userSnap = await userRef.get();

    if (!userSnap.exists) return res.status(404).json({ message: 'User not found' });

    const user = userSnap.data();
    if (user.verificationCode !== code) return res.status(400).json({ message: 'Invalid verification code' });

    const now = Date.now();
    if (user.verificationCodeExpires < now) return res.status(400).json({ message: 'Code expiré' });

    await userRef.update({ isVerified: true });
    res.json({ message: 'Email vérifié avec succès' });
  } catch (error) {
    res.status(500).json({ message: 'Erreur de vérification', error: error.message });
  }
});

// Resend code route
app.post('/api/resend-code', async (req, res) => {
  try {
    const { email } = req.body;
    const userRef = db.collection('users').doc(email);
    const userDoc = await userRef.get();

    if (!userDoc.exists) return res.status(404).json({ message: 'Email non enregistré' });

    const newCode = generateVerificationCode();
    const newExpires = Date.now() + 900000;

    await userRef.update({ verificationCode: newCode, verificationCodeExpires: newExpires });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Nouveau Code de Vérification',
      html: `<p>Votre nouveau code est : <strong>${newCode}</strong></p>`
    };
    await transporter.sendMail(mailOptions);

    res.status(200).json({ message: 'Code renvoyé avec succès' });
  } catch (error) {
    res.status(500).json({ message: 'Erreur de renvoi', error: error.message });
  }
});

// Sign in route
app.post('/api/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    const userSnap = await db.collection('users').doc(email).get();

    if (!userSnap.exists) return res.status(404).json({ message: 'User not found' });

    const user = userSnap.data();
    if (!user.isVerified) return res.status(401).json({ message: 'Please verify your email first' });

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) return res.status(401).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ userId: user.uid, email: user.email, accountType: user.accountType }, process.env.JWT_SECRET, { expiresIn: '1h' });

    res.json({ token, user: { email: user.email, username: user.username, accountType: user.accountType } });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});



// Update account type
app.post('/api/account-type', async (req, res) => {
  try {
    const { email, accountType } = req.body;
    if (!['client', 'commerçant'].includes(accountType)) return res.status(400).json({ message: 'Invalid account type' });

    await db.collection('users').doc(email).update({ accountType });
    res.json({ message: 'Account type updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
//merchant
// backend Node.js avec Firebase Storage et multer pour gérer l'upload
app.post('/api/merchant/register', upload.fields([
  { name: 'logo', maxCount: 1 },
  { name: 'images', maxCount: 1 }, // Devanture
]), async (req, res) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Token manquant ou invalide' });
    }

    const idToken = authHeader.split(' ')[1];
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const email = decodedToken.email;

    const { commerceName, commerceType, address, phone } = req.body;
    const files = req.files;
    const uploads = {};

    // Upload images to Firebase Storage
    if (files.logo && files.logo[0]) {
      const file = files.logo[0];
      const filename = `${uuidv4()}_${file.originalname}`;
      const fileUpload = bucket.file(filename);

      await fileUpload.save(file.buffer, { metadata: { contentType: file.mimetype } });
      uploads.logoUrl = `https://storage.googleapis.com/${bucket.name}/${filename}`;
    }

    if (files.images && files.images[0]) {
      const file = files.images[0];
      const filename = `${uuidv4()}_${file.originalname}`;
      const fileUpload = bucket.file(filename);

      await fileUpload.save(file.buffer, { metadata: { contentType: file.mimetype } });
      uploads.storeImageUrl = `https://storage.googleapis.com/${bucket.name}/${filename}`;
    }

    // Enregistrement Firestore
    await db.collection('merchants').add({
      email,
      commerceName,
      commerceType,
      address,
      phone,
      logoUrl: uploads.logoUrl || null,
      storeImageUrl: uploads.storeImageUrl || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({ message: 'Commerçant enregistré avec succès' });
  } catch (error) {
    console.error('Erreur d\'enregistrement commerçant:', error);
    res.status(500).json({ message: 'Erreur serveur: ' + error.message });
  }
});

// Enregistrement de la localisation du client
app.post('/api/client/location', async (req, res) => {
  try {
    const { email, address, phone } = req.body;

    if (!email || !address || !phone) {
      return res.status(400).json({ message: 'Tous les champs sont requis' });
    }

    const userRef = db.collection('users').doc(email);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    await userRef.update({
      address,
      phone,
      locationUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({ message: 'Localisation enregistrée avec succès' });
  } catch (error) {
    console.error('Erreur lors de l\'enregistrement de la localisation :', error);
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
});


// Delete user
app.delete('/api/delete-user', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email is required' });

    const user = await auth.getUserByEmail(email);
    await auth.deleteUser(user.uid);
    await db.collection('users').doc(email).delete();

    res.status(200).json({ message: `User with email ${email} deleted successfully.` });
  } catch (error) {
    res.status(500).json({ message: 'Failed to delete user', error: error.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Firebase project: ${admin.app().options.credential.projectId}`);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ message: 'Internal server error' });
});
