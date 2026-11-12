const mongoose = require('mongoose');

const RouteSchema = new mongoose.Schema(
  {
    routeCode: { type: String, required: true, unique: true },
    routeName: { type: String, required: true },
    startPoint: { type: String },
    endPoint: { type: String },
    stopsCount: { type: Number, default: 8 },
    activeBuses: { type: Number, default: 3 }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Route', RouteSchema);
