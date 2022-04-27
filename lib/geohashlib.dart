// https://github.com/firebase/geofire-js/tree/master/packages/geofire-common

import 'dart:math';
import 'package:tuple/tuple.dart';
import 'package:collection/collection.dart';

// Default geohash length
const int GEOHASH_PRECISION = 10;

// Characters used in location geohashes
const String BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

// The meridional circumference of the earth in meters
const int EARTH_MERI_CIRCUMFERENCE = 40007860;

// Length of a degree latitude at the equator
const int METERS_PER_DEGREE_LATITUDE = 110574;

// Number of bits per geohash character
const int BITS_PER_CHAR = 5;

// Maximum length of a geohash in bits
const int MAXIMUM_BITS_PRECISION = 22 * BITS_PER_CHAR;

// Equatorial radius of the earth in meters
const double EARTH_EQ_RADIUS = 6378137.0;

// The following value assumes a polar radius of
// const EARTH_POL_RADIUS = 6356752.3;
// The formulate to calculate E2 is
// E2 == (EARTH_EQ_RADIUS^2-EARTH_POL_RADIUS^2)/(EARTH_EQ_RADIUS^2)
// The exact value is used here to avoid rounding errors
const double E2 = 0.00669447819799;
const double EPSILON = 1e-12;

typedef Latitude = double;
typedef Longitude = double;
typedef GeoPoint = Tuple2<Latitude, Longitude>;
typedef GeoHash = String;
typedef GeoHashRange = Map<String, GeoHash>;

double log2(double x) {
  return log(x) / log(2);
}

GeoPoint geoPointForDouble(double latitude, double longitude) {
  return Tuple2(latitude, longitude);
}

void validateLocation(GeoPoint location) {
  // if (!location.containsKey("latitude") ||
  //     !location.containsKey(("longitude"))) {
  //   throw new ArgumentError(
  //       location, "location must have latitude and longitude key/");
  // }
  Latitude lat = location.item1;
  Longitude lon = location.item2;

  if (lat < -90 || lat > 90) {
    throw new ArgumentError(location, "latitude is out of lange.");
  } else if (lon < -180 || lon > 180) {
    throw new ArgumentError(location, "longitude is out of lange.");
  }
}

void validateGeoHash(GeoHash geohash) {
  if (geohash.length == 0) {
    throw new ArgumentError(geohash, "geohash cannot be the empty string");
  }
  for (int i = 0; i < geohash.length; i++) {
    var char = geohash[i];
    if (!BASE32.contains(char)) {
      throw new ArgumentError(geohash, "geohash cannot contain '" + char + "'");
    }
  }
}

double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

GeoHash geohashForLocation(GeoPoint location,
    {int precision = GEOHASH_PRECISION}) {
  validateLocation(location);
  if (precision <= 0) {
    throw new ArgumentError("precision must be greater than 0.");
  } else if (precision > 22) {
    throw new ArgumentError("precision cannot be greater than 22.");
  }

  Map<String, double> latutudeRange = {"min": -90, "max": 90};
  Map<String, double> longitudeRange = {"min": -180, "max": 180};

  var hash = "";
  var coin = true;
  while (hash.length < precision) {
    var bits = 0;
    for (int i = 0; i < BITS_PER_CHAR; i++) {
      var val = coin ? location.item2 : location.item1;
      var range = coin ? longitudeRange : latutudeRange;
      var mid = (range["min"]! + range["max"]!) / 2;

      if (val > mid) {
        bits = (bits << 1) + 1;
        range.update("min", (val) => mid);
      } else {
        bits = (bits << 1) + 0;
        range.update("max", (val) => mid);
      }
      coin = !coin;
    }
    hash = hash + BASE32[bits];
  }

  return hash;
}

double metersToLongitudeDegrees(double distance, Latitude latitude) {
  double radians = degreesToRadians(latitude);
  double num = cos(radians) * EARTH_EQ_RADIUS * pi / 180;
  double denom = 1 / sqrt(1 - E2 * sin(radians) * sin(radians));
  double deltaDeg = num * denom;
  if (deltaDeg < EPSILON) {
    return distance > 0 ? 360 : 0;
  } else {
    return min(360, distance / deltaDeg);
  }
}

double longitudeBitsForResolution(double resolution, Latitude latitude) {
  double degs = metersToLongitudeDegrees(resolution, latitude);
  // print("resolution: " +
  //     resolution.toString() +
  //     " latitude: " +
  //     latitude.toString() +
  //     " degs: " +
  //     degs.toString());
  return (degs.abs() > 0.000001) ? max(1, log2(360 / degs)) : 1;
}

double latitudeBitsForResolution(double resolution) {
  return min(log2(EARTH_MERI_CIRCUMFERENCE / 2 / resolution),
      MAXIMUM_BITS_PRECISION.toDouble());
}

double wrapLongitude(double longitude) {
  if (longitude <= 180 && longitude >= -180) {
    return longitude;
  }
  var adjusted = longitude + 180;
  if (adjusted > 0) {
    return (adjusted % 360) - 180;
  } else {
    return 180 - (-adjusted % 360);
  }
}

int boundingBoxBits(GeoPoint coordinate, int size) {
  double latDeltaDegrees = size / METERS_PER_DEGREE_LATITUDE;
  double latitudeNorth = min(90, coordinate.item1 + latDeltaDegrees);
  double latitudeSouth = max(-90, coordinate.item1 + latDeltaDegrees);
  int bitsLat = latitudeBitsForResolution(size.toDouble()).floor() * 2;
  int bitsLongNorth =
      longitudeBitsForResolution(size.toDouble(), latitudeNorth).floor() * 2 -
          1;
  int bitsLongSouth =
      longitudeBitsForResolution(size.toDouble(), latitudeSouth).floor() * 2 -
          1;
  return min(
      bitsLat, min(min(bitsLongNorth, bitsLongSouth), MAXIMUM_BITS_PRECISION));
}

List<GeoPoint> boundingBoxCoordinates(GeoPoint center, double radius) {
  var latDegrees = radius / METERS_PER_DEGREE_LATITUDE;
  double latitudeNorth = min(90, center.item1 + latDegrees);
  double latitudeSouth = max(-90, center.item1 + latDegrees);
  var longDegsNorth = metersToLongitudeDegrees(radius, latitudeNorth);
  var longDegsSouth = metersToLongitudeDegrees(radius, latitudeSouth);
  var longDegs = max(longDegsNorth, longDegsSouth);

  return [
    center,
    Tuple2(center.item1, wrapLongitude(center.item1 - longDegs)),
    Tuple2(center.item1, wrapLongitude(center.item1 + longDegs)),
    Tuple2(latitudeNorth, center.item2),
    Tuple2(latitudeNorth, wrapLongitude(center.item2 - longDegs)),
    Tuple2(latitudeNorth, wrapLongitude(center.item2 + longDegs)),
    Tuple2(latitudeSouth, center.item2),
    Tuple2(latitudeSouth, wrapLongitude(center.item2 - longDegs)),
    Tuple2(latitudeSouth, wrapLongitude(center.item2 + longDegs)),
  ];
}

GeoHashRange geohashQuery(GeoHash geohash, int bits) {
  validateGeoHash(geohash);

  final int precision = (bits / BITS_PER_CHAR).ceil();
  if (geohash.length < precision) {
    return {"start": geohash, "end": geohash + "~"};
  }
  geohash = geohash.substring(0, precision);
  final String base = geohash.substring(0, geohash.length - 1);
  final int lastValue =
      BASE32.indexOf(geohash.substring(geohash.length - 1, geohash.length));
  final int significantBits = bits - (base.length * BITS_PER_CHAR);
  final int unusedBits = (BITS_PER_CHAR - significantBits);
  final int startValue = (lastValue >> unusedBits) << unusedBits;
  final int endValue = startValue + (1 << unusedBits);
  if (endValue > 31) {
    return {"start": base + BASE32[startValue], "end": base + "~"};
  } else {
    return {"start": base + BASE32[startValue], "end": base + BASE32[endValue]};
  }
}

List<GeoHashRange> geohashQueryBounds(GeoPoint center, double radius) {
  validateLocation(center);
  int queryBits = max(1, boundingBoxBits(center, radius.toInt()));
  var geohashPrecision = (queryBits / BITS_PER_CHAR).ceil();
  var coordinates = boundingBoxCoordinates(center, radius);
  var queries = coordinates.map<GeoHashRange>((coordinate) {
    return geohashQuery(
        geohashForLocation(coordinate, precision: geohashPrecision), queryBits);
  }).toList();

  return queries.whereIndexed((index, item) {
    bool tf = true;
    queries.forEachIndexed((idx, some) {
      if (idx > index &&
          item["start"]! == some["start"]! &&
          item["end"]! == some["end"]!) {
        tf = false;
      }
    });
    return tf;
  }).toList();
}

double distanceBetween(GeoPoint location1, GeoPoint location2) {
  validateLocation(location1);
  validateLocation(location2);
  var radius = 6371;
  var latDelta = degreesToRadians(location2.item1 - location1.item1);
  var lonDelta = degreesToRadians(location2.item2 - location1.item2);

  var a = sin(latDelta / 2) * sin(latDelta / 2) +
      cos(degreesToRadians((location1.item1))) *
          cos(degreesToRadians(location2.item1)) *
          sin(lonDelta / 2) *
          sin(lonDelta / 2);
  var c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return radius * c;
}
