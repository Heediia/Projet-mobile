require('dotenv').config();
const express = require('express');
const admin = require('firebase-admin');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const cors = require('cors');
const app = express();

app.use(express.json());
app.use(cors(({
  origin: '*', // Allow all origins (for testing)
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
})));

// Firebase Admin SDK
const serviceAccount = require('./ballouchi-23808-firebase-adminsdk-fbsvc-1c6677b5d5.json'); // Change le chemin si nécessaire
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

// ✅ ADD THE TEST ENDPOINT RIGHT HERE ✅
app.get('/api/test-firebase', async (req, res) => {
  try {
    // Test Firestore connection
    const testRef = db.collection('testConnection').doc('testDoc');
    await testRef.set({ timestamp: new Date() });
    const doc = await testRef.get();
    
    // Test Firebase Admin Auth
    await admin.auth().listUsers(1);
    
    res.json({
      firestore: 'connected',
      auth: 'connected',
      testDocument: doc.exists ? doc.data() : null
    });
  } catch (error) {
    res.status(500).json({
      error: 'Firebase connection failed',
      details: error.message
    });
  }
});

// Email transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Fonction pour générer un code à 4 chiffres
function generateVerificationCode() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// ➕ Inscription
app.post('/api/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // 1. Check if user already exists
    const userRef = db.collection('users').doc(email); // Use email as document ID
    const userDoc = await userRef.get();

    if (userDoc.exists) {
      return res.status(400).json({ message: 'Email already in use' });
    }

    // 2. Hash password and generate verification code
    const hashedPassword = await bcrypt.hash(password, 10);
    const verificationCode = generateVerificationCode();

    // 3. Save to Firestore (structured data)
    await userRef.set({
      username,
      email,
      password: hashedPassword,
      isVerified: false,
      verificationCode,
      accountType: 'client', // Default role
      createdAt: admin.firestore.FieldValue.serverTimestamp() // Auto-add timestamp
    });

    // 4. Send verification email (optional)
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Verify Your Email',
      text: `Your code: ${verificationCode}`
    };
    await transporter.sendMail(mailOptions);

    // 5. Success response
    res.status(201).json({ 
      message: 'User registered! Check your email for verification.' 
    });

  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ message: 'Server error. Try again later.' });
  }
});

// 🔁 Mise à jour du type de compte
app.post('/api/set-account-type', async (req, res) => {
  try {
    const { email, accountType } = req.body;

    const userRef = db.collection('users').doc(email);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      return res.status(404).json({ message: 'User not found' });
    }

    await userRef.update({ accountType });

    res.json({ message: 'Account type set successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 🔓 Connexion
app.post('/api/signin', async (req, res) => {
  try {
    const { email, password } = req.body;

    const userSnap = await db.collection('users').doc(email).get();
    if (!userSnap.exists) {
      return res.status(404).json({ message: 'User not found' });
    }

    const user = userSnap.data();

    if (!user.isVerified) {
      return res.status(401).json({ message: 'Email not verified' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: email, accountType: user.accountType },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.json({ token, accountType: user.accountType });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 🔊 Lancer le serveur
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
