require('dotenv').config();
const express = require('express');
const admin = require('firebase-admin');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const cors = require('cors');
const app = express();
const multer = require('multer');


// Configuration de stockage
const storage = multer.memoryStorage(); // ou diskStorage si tu veux enregistrer les fichiers localement
const upload = multer({ storage: storage });

// Middleware
app.use(express.json());
app.use(cors({
  origin: '*', // In production, replace with your frontend URL
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Firebase Admin SDK Initialization
try {
  const serviceAccount = require('./ballouchi-23808-firebase-adminsdk-fbsvc-6b778e9a66.json');
  
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: serviceAccount.project_id,
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key.replace(/\\n/g, '\n'),
    }),
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://ballouchi-23808.firebaseio.com',
    storageBucket: 'ballouchi-23808.appspot.com'
  });

  console.log("Firebase Admin initialized successfully");
} catch (error) {
  console.error("Firebase Admin initialization error:", error);
  process.exit(1);
}

const db = admin.firestore();
const auth = admin.auth();

// Email transporter setup
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Helper functions
function generateVerificationCode() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// Test endpoint
app.get('/api/test-firebase', async (req, res) => {
  try {
    const testRef = db.collection('testConnection').doc('testDoc');
    await testRef.set({ timestamp: admin.firestore.FieldValue.serverTimestamp() });
    const doc = await testRef.get();
    await auth.listUsers(1);

    res.json({
      status: 'success',
      firestore: 'working',
      auth: 'working',
      testDocument: doc.data(),
    });
  } catch (error) {
    console.error('Firebase test error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Firebase connection failed',
      error: error.message,
    });
  }
});

// Ajoutez cette map pour gérer les codes temporairement
const verificationCodes = new Map();

// Modifiez le endpoint /api/signup
app.post('/api/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    
    // Vérification des champs requis
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'Tous les champs sont requis' });
    }

    // Vérification de l'email existant
    const userRef = db.collection('users').doc(email);
    const userDoc = await userRef.get();
    
    if (userDoc.exists) {
      return res.status(400).json({ message: 'Email déjà utilisé' });
    }

    // Création de l'utilisateur Firebase
    const firebaseUser = await auth.createUser({
      email,
      password,
      displayName: username
    });

    // Génération du code de vérification
    const verificationCode = generateVerificationCode();
    const verificationCodeExpires = Date.now() + 900000; // 15 minutes

    // Stockage temporaire
    verificationCodes.set(email, {
      code: verificationCode,
      expires: verificationCodeExpires
    });

    // Envoi du code par email
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Code de Vérification Ballouchi',
      html: `
        <h2>Bienvenue sur Ballouchi!</h2>
        <p>Votre code de vérification est : <strong>${verificationCode}</strong></p>
        <p>Ce code expirera dans 15 minutes.</p>
      `
    };

    await transporter.sendMail(mailOptions);

    res.status(201).json({
      message: 'Code de vérification envoyé avec succès',
      email
    });

  } catch (error) {
    console.error('Erreur d\'inscription:', error);
    res.status(500).json({
      message: 'Erreur du serveur',
      error: error.message
    });
  }
});

// Ajoutez ce endpoint pour le renvoi de code
app.post('/api/resend-code', async (req, res) => {
  try {
    const { email } = req.body;

    if (!verificationCodes.has(email)) {
      return res.status(404).json({ message: 'Aucun code actif pour cet email' });
    }

    // Générer un nouveau code
    const newCode = generateVerificationCode();
    const newExpiration = Date.now() + 900000; // 15 minutes
    
    verificationCodes.set(email, {
      code: newCode,
      expires: newExpiration
    });

    // Renvoyer le code par email
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Nouveau Code de Vérification',
      html: `
        <h2>Nouveau code Ballouchi</h2>
        <p>Votre nouveau code est : <strong>${newCode}</strong></p>
        <p>Ce code expirera dans 15 minutes.</p>
      `
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({ message: 'Nouveau code envoyé avec succès' });

  } catch (error) {
    res.status(500).json({
      message: 'Erreur de renvoi',
      error: error.message
    });
  }
});

// Modifiez le endpoint de vérification
app.post('/api/verify', async (req, res) => {
  try {
    const { email, code } = req.body;

    const record = verificationCodes.get(email);

    if (!record) {
      return res.status(400).json({ message: 'Aucun code associé à cet email' });
    }

    if (record.code !== code) {
      return res.status(400).json({ message: 'Code de vérification incorrect' });
    }

    if (Date.now() > record.expires) {
      verificationCodes.delete(email);
      return res.status(400).json({ message: 'Code expiré' });
    }

    // Création de l'utilisateur dans Firestore
    const userRef = db.collection('users').doc(email);
    await userRef.set({
      email,
      isVerified: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Suppression du code temporaire
    verificationCodes.delete(email);

    res.status(200).json({ 
      message: 'Vérification réussie',
      verified: true 
    });

  } catch (error) {
    res.status(500).json({
      message: 'Erreur de vérification',
      error: error.message
    });
  }
});
app.post('/api/merchant/register', upload.fields([
  { name: 'logo', maxCount: 1 },
  { name: 'images', maxCount: 5 }
]), async (req, res) => {
  try {
    const { commerceName, commerceType, address, phone } = req.body;
    const files = req.files;
    const uploads = {};

    // Upload files
    for (const key in files) {
      const file = files[key][0];
      const filename = `${uuidv4()}_${file.originalname}`;
      const fileUpload = bucket.file(filename);

      await fileUpload.save(file.buffer, {
        metadata: {
          contentType: file.mimetype,
        },
      });

      uploads[key] = `https://storage.googleapis.com/${bucket.name}/${filename}`;
    }

    await db.collection('merchants').add({
      commerceName,
      commerceType,
      address,
      phone,
      logoUrl: uploads.logo || null,
      storeImageUrl: uploads.storeImage || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).send({ message: 'Merchant enregistré avec succès' });
  } catch (error) {
    console.error(error);
    res.status(500).send({ error: error.message });
  }
});

// Signin endpoint
app.post('/api/signin', async (req, res) => {
  try {
    const { email, password } = req.body;

    const userSnap = await db.collection('users').doc(email).get();
    if (!userSnap.exists) {
      return res.status(404).json({ message: 'User not found' });
    }

    const user = userSnap.data();

    if (!user.isVerified) {
      return res.status(401).json({ message: 'Please verify your email first' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { 
        userId: user.uid,
        email: user.email,
        accountType: user.accountType,
      },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.json({ 
      token,
      user: {
        email: user.email,
        username: user.username,
        accountType: user.accountType,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Email verification endpoint
app.post('/api/verify', async (req, res) => {
  try {
    const { email, code } = req.body;

    const userRef = db.collection('users').doc(email);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      return res.status(404).json({ message: 'User not found' });
    }

    const user = userSnap.data();

    if (user.verificationCode !== code) {
      return res.status(400).json({ message: 'Invalid verification code' });
    }

    const currentTimestamp = admin.firestore.Timestamp.now();

    if (user.verificationCodeExpires && user.verificationCodeExpires.toMillis() < currentTimestamp.toMillis()) {
      return res.status(400).json({ message: 'Verification code has expired' });
    }

    await userRef.update({
      isVerified: true,
    });

    res.json({ message: 'Email successfully verified' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});
// Ajoutez cette route avant les autres endpoints
app.post('/api/resend-code', async (req, res) => {
  try {
    const { email } = req.body;
    
    // Vérifier si l'email existe dans la base de données
    const userRef = db.collection('users').doc(email);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ message: 'Email non enregistré' });
    }

    // Générer un nouveau code
    const newCode = generateVerificationCode();
    const newExpires = Date.now() + 900000; // 15 minutes

    // Mettre à jour dans Firestore
    await userRef.update({
      verificationCode: newCode,
      verificationCodeExpires: newExpires
    });

    // Envoyer le nouvel email
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Nouveau Code de Vérification',
      html: `<p>Votre nouveau code est : <strong>${newCode}</strong></p>`
    };

    await transporter.sendMail(mailOptions);

    res.status(200).json({ message: 'Code renvoyé avec succès' });

  } catch (error) {
    console.error('Resend error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Account type update endpoint
app.post('/api/account-type', async (req, res) => {
  try {
    const { email, accountType } = req.body;

    if (!['client', 'commerçant'].includes(accountType)) {
      return res.status(400).json({ message: 'Invalid account type' });
    }

    const userRef = db.collection('users').doc(email);
    await userRef.update({ accountType });

    res.json({ message: 'Account type updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 🔥 Delete user by email
app.delete('/api/delete-user', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().deleteUser(user.uid);
    await db.collection('users').doc(email).delete();

    res.status(200).json({ message: `User with email ${email} deleted successfully.` });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ message: 'Failed to delete user', error: error.message });
  }
});

// Server startup
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
