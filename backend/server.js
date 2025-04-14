require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));

// User Schema
const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  isVerified: { type: Boolean, default: false },
  verificationCode: { type: String },
  accountType: { type: String, enum: ['commerçant', 'client'], default: 'client' }
});

const User = mongoose.model('User', userSchema);

// Email transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Generate random 4-digit code
function generateVerificationCode() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// Routes
app.post('/api/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    
    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already in use' });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Generate verification code
    const verificationCode = generateVerificationCode();
    
    // Create user
    const user = new User({
      username,
      email,
      password: hashedPassword,
      verificationCode
    });
    
    await user.save();
    
    // Send verification email
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Email Verification Code',
      text: `Your verification code is: ${verificationCode}`
    };
    
    await transporter.sendMail(mailOptions);
    
    res.status(201).json({ message: 'User created. Verification code sent to email.' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/verify', async (req, res) => {
  try {
    const { email, code } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    if (user.verificationCode !== code) {
      return res.status(400).json({ message: 'Invalid verification code' });
    }
    
    user.isVerified = true;
    user.verificationCode = undefined;
    await user.save();
    
    res.json({ message: 'Email verified successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/set-account-type', async (req, res) => {
  try {
    const { email, accountType } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    user.accountType = accountType;
    await user.save();
    
    res.json({ message: 'Account type set successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    if (!user.isVerified) {
      return res.status(401).json({ message: 'Email not verified' });
    }
    
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, accountType: user.accountType },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    res.json({ token, accountType: user.accountType });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));