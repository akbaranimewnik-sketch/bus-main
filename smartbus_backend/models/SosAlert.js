const mongoose = require('mongoose');

const SosAlertSchema = new mongoose.Schema(
  {
    busCode: { type: String, required: true },
    routeName: { type: String },
    driverName: { type: String },
    latitude: { type: Number },
    longitude: { type: Number },
    message: { type: String, default: 'FAVQULOTDE HOLAT ALARM' },
    isResolved: { type: Boolean, default: false }
  },
  { timestamps: true }
);

module.exports = mongoose.model('SosAlert', SosAlertSchema);
