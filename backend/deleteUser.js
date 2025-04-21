// deleteUser.js
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

async function deleteUserByEmail(email) {
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().deleteUser(user.uid);
    console.log('User deleted successfully');
  } catch (error) {
    console.error('Error deleting user:', error);
  }
}

// Replace with the email you want to delete
deleteUserByEmail('hediakouni@gmail.com');