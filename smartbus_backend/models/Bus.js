const mongoose = require('mongoose');

const BusSchema = new mongoose.Schema(
  {
    busId: { type: String, required: true, unique: true },
    busCode: { type: String, required: true },
    routeName: { type: String, required: true },
    driverName: { type: String, required: true },
    speed: { type: Number, default: 0 },
    occupancyPercent: { type: Number, default: 0 },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    dLat: { type: Number, default: 0.0002 },
    dLng: { type: Number, default: 0.0003 },
    status: { type: String, enum: ['ok', 'late', 'sos', 'stopped'], default: 'ok' },
    eta: { type: Number, default: 5 }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Bus', BusSchema);
