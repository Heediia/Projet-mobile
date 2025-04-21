require('dotenv').config();
const express = require('express');
const admin = require('firebase-admin');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const cors = require('cors');
const app = express();

// Middleware
app.use(express.json());
app.use(cors({
  origin: '*', // In production, replace with your frontend URL
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Firebase Admin SDK Initialization
try {
  const serviceAccount = require('./ballouchi-23808-firebase-adminsdk-fbsvc-d595c6c2df.json');
  
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: serviceAccount.project_id,
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key.replace(/\\n/g, '\n'),
    }),
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://<ballouchi-23808>.firebaseio.com',
    storageBucket: '<ballouchi-23808>.appspot.com'
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

// Signup endpoint
app.post('/api/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    console.log("Signup request received:", { username, email });

    const userRef = db.collection('users').doc(email);
    const userDoc = await userRef.get();

    if (userDoc.exists) {
      return res.status(400).json({ message: 'Email already in use' });
    }

    let firebaseUser;
    try {
      firebaseUser = await auth.createUser({
        email: email,
        displayName: username,
        password: password,
      });
    } catch (authError) {
      console.error('Firebase Auth error:', authError);
      return res.status(400).json({ message: 'User creation failed', error: authError.message });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const verificationCode = generateVerificationCode();
    const verificationCodeExpires = admin.firestore.FieldValue.serverTimestamp();

    await userRef.set({
      uid: firebaseUser.uid,
      username,
      email,
      password: hashedPassword,
      isVerified: false,
      verificationCode,
      verificationCodeExpires,
      accountType: 'client',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Verify Your Email',
      html: `
        <h2>Welcome to Ballouchi!</h2>
        <p>Your verification code is: <strong>${verificationCode}</strong></p>
        <p>Enter this code in the app to verify your email address.</p>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("Verification email sent to", email);

    res.status(201).json({ 
      message: 'User registered successfully! Please check your email for verification.',
      userId: firebaseUser.uid,
    });

  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ 
      message: 'Registration failed',
      error: error.message,
    });
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

// Account type update endpoint
app.post('/api/account-type', async (req, res) => {
  try {
    const { email, accountType } = req.body;

    if (!['client', 'professional'].includes(accountType)) {
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
