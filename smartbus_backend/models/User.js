const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    fullName: { type: String, required: true },
    phoneNumber: { type: String, default: '' },
    username: { type: String, default: '' },
    password: { type: String, required: true },
    busCode: { type: String, default: '' },
    routeName: { type: String, default: '' },
    role: {
      type: String,
      enum: ['passenger', 'driver', 'admin'],
      default: 'passenger'
    },
    isOnline: { type: Boolean, default: false },
    lastLogin: { type: Date }
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', UserSchema);
