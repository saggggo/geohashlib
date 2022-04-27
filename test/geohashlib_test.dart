import 'dart:math';

import 'package:test/test.dart';
import "package:tuple/tuple.dart";
import 'package:geohashlib/geohashlib.dart';

void main() {
  group("validateLocation", () {
    test('latitude or longitude out of range.', () {
      GeoPoint p = Tuple2(90.001, 0);
      expect(() => validateLocation(p), throwsArgumentError);
      p = Tuple2(-90.001, 0);
      expect(() => validateLocation(p), throwsArgumentError);
      p = Tuple2(0, 180.001);
      expect(() => validateLocation(p), throwsArgumentError);
      p = Tuple2(0, -180.001);
      expect(() => validateLocation(p), throwsArgumentError);
      p = Tuple2(90.001, 180.001);
      expect(() => validateLocation(p), throwsArgumentError);
    });
  });
  group("validateGeoHash()", () {
    test('geohash is empty.', () {
      GeoHash h = "";
      expect(() => validateGeoHash(h), throwsArgumentError);
    });

    test('geohash contain unexpected character.', () {
      GeoHash h = "284ZXc";
      expect(() => validateGeoHash(h), throwsArgumentError);
    });
  });

  group("degreesToRadians()", () {
    test("180 degrees is pi", () {
      expect(degreesToRadians(180), equals(pi));
    });

    test("450 degrees is 5/2pi", () {
      expect(degreesToRadians(450), equals(5 * pi / 2));
    });
  });

  group("geohashForLocation()", () {
    test("presition must be 22 >= x > 0", () {
      GeoPoint P = Tuple2(3, 3);
      expect(() => geohashForLocation(P, precision: -1), throwsArgumentError);
      expect(() => geohashForLocation(P, precision: 23), throwsArgumentError);
    });

    test("geohash with no precision ", () {
      expect(geohashForLocation(Tuple2(-90, -180)), equals('0000000000'));
      expect(geohashForLocation(Tuple2(90, 180)), equals('zzzzzzzzzz'));
      expect(geohashForLocation(Tuple2(-90, 180)), equals('pbpbpbpbpb'));
      expect(geohashForLocation(Tuple2(90, -180)), equals('bpbpbpbpbp'));
      expect(
          geohashForLocation(Tuple2(57.64911, 10.40744)), equals("u4pruydqqv"));
      expect(geohashForLocation(Tuple2(35.9190748, 139.90842)),
          equals("xn7krdy5y2"));
    });

    test("geohash with precision ", () {
      expect(geohashForLocation(Tuple2(-90, -180), precision: 6),
          equals('000000'));
      expect(geohashForLocation(Tuple2(90, 180), precision: 20),
          equals('zzzzzzzzzzzzzzzzzzzz'));
      expect(geohashForLocation(Tuple2(-90, 180), precision: 1), equals('p'));
      expect(geohashForLocation(Tuple2(90, -180), precision: 3), equals('bpb'));
      expect(geohashForLocation(Tuple2(57.64911, 10.40744), precision: 4),
          equals("u4pr"));
      expect(geohashForLocation(Tuple2(35.9190748, 139.90842), precision: 10),
          equals("xn7krdy5y2"));
    });
  });

  group("wrapLongitude", () {
    test("test", () {
      expect(wrapLongitude(180), equals(180));
      expect(wrapLongitude(181), equals(-179));
      expect(wrapLongitude(-180), equals(-180));
      expect(wrapLongitude(-181), equals(179));
    });
  });
  group("boundingBoxCoordinates()", () {
    test("test", () {
      expect(
        boundingBoxCoordinates(Tuple2(35.9190748, 139.90842), 500),
        equals([
          Tuple2(35.9190748, 139.90842),
          Tuple2(35.9190748, 35.91353466935332),
          Tuple2(35.9190748, 35.924614930646676),
          Tuple2(35.923596658664785, 139.90842),
          Tuple2(35.923596658664785, 139.90287986935334),
          Tuple2(35.923596658664785, 139.91396013064667),
          Tuple2(35.923596658664785, 139.90842),
          Tuple2(35.923596658664785, 139.90287986935334),
          Tuple2(35.923596658664785, 139.91396013064667)
        ]),
      );
    });
  });

  group("boundingBoxBits()", () {
    test("", () {
      expect(boundingBoxBits(Tuple2(35, 0), 1000), equals(28));
      expect(boundingBoxBits(Tuple2(35.645, 0), 1000), equals(27));
      expect(boundingBoxBits(Tuple2(36, 0), 1000), equals(27));
      expect(boundingBoxBits(Tuple2(0, 0), 1000), equals(28));
      expect(boundingBoxBits(Tuple2(0, -180), 1000), equals(28));
      expect(boundingBoxBits(Tuple2(0, 180), 1000), equals(28));
      expect(boundingBoxBits(Tuple2(0, 0), 8000), equals(22));
      expect(boundingBoxBits(Tuple2(45, 0), 1000), equals(27));
      expect(boundingBoxBits(Tuple2(75, 0), 1000), equals(25));
      expect(boundingBoxBits(Tuple2(75, 0), 2000), equals(23));
      expect(boundingBoxBits(Tuple2(90, 0), 1000), equals(1));
      expect(boundingBoxBits(Tuple2(90, 0), 2000), equals(1));
    });
  });
  // group("geohashQUeryBounds()", () {
  //   test("test", () {
  //     expect(geohashQueryBounds(Tuple2(35.9190748, 139.90842), 500), equals(1));
  //   });
  // });
  group('distanceBetween()', () {
    test("test", () {
      expect(distanceBetween(Tuple2(90, 180), Tuple2(90, 180)), closeTo(0, 0));
      expect(distanceBetween(Tuple2(-90, -180), Tuple2(90, 180)),
          closeTo(20015, 1));
      expect(
          distanceBetween(Tuple2(-90, -180), Tuple2(-90, 180)), closeTo(0, 1));
      expect(distanceBetween(Tuple2(-90, -180), Tuple2(90, -180)),
          closeTo(20015, 1));
      expect(
          distanceBetween(
              Tuple2(37.7853074, -122.4054274), Tuple2(78.216667, 15.55)),
          closeTo(6818, 1));
      expect(
          distanceBetween(
              Tuple2(38.98719, -77.250783), Tuple2(29.3760648, 47.9818853)),
          closeTo(10531, 1));
      expect(
          distanceBetween(
              Tuple2(38.98719, -77.250783), Tuple2(-54.933333, -67.616667)),
          closeTo(10484, 1));
      expect(
          distanceBetween(
              Tuple2(29.3760648, 47.9818853), Tuple2(-54.933333, -67.616667)),
          closeTo(14250, 1));
      expect(distanceBetween(Tuple2(-54.933333, -67.616667), Tuple2(-54, -67)),
          closeTo(111, 1));
    });
  });
  group('Geohash queries:', () {
    test('Geohash queries must be of the right size', () {
      expect(
          geohashQuery('64m9yn96mx', 6), equals({"start": '60', "end": '6h'}));
      expect(geohashQuery('64m9yn96mx', 1), equals({"start": '0', "end": 'h'}));
      expect(
          geohashQuery('64m9yn96mx', 10), equals({"start": '64', "end": '65'}));
      expect(geohashQuery('6409yn96mx', 11),
          equals({"start": '640', "end": '64h'}));
      expect(geohashQuery('64m9yn96mx', 11),
          equals({"start": '64h', "end": '64~'}));
      expect(geohashQuery('6', 10), equals({"start": '6', "end": '6~'}));
      expect(
          geohashQuery('64z178', 12), equals({"start": '64s', "end": '64~'}));
      expect(
          geohashQuery('64z178', 15), equals({"start": '64z', "end": '64~'}));
    });

    test('Query bounds from geohashQueryBounds must contain points in circle',
        () {
      bool inQuery(List<Map<String, String>> queries, String hash) {
        for (var i = 0; i < queries.length; i++) {
          if (hash.compareTo(queries[i]["start"]!) > 0 &&
              hash.compareTo(queries[i]["end"]!) < 0) {
            return true;
          }
        }
        return false;
      }

      for (var i = 0; i < 200; i++) {
        var rand = new Random();
        double centerLat = pow(rand.nextDouble(), 5) * 160 - 80;
        double centerLong = pow(rand.nextDouble(), 5) * 360 - 180;
        double radius = rand.nextDouble() * rand.nextDouble() * 100000;
        double degreeRadius = metersToLongitudeDegrees(radius, centerLat);
        var queries = geohashQueryBounds(Tuple2(centerLat, centerLong), radius);
        for (var j = 0; j < 1000; j++) {
          var pointLat = max(
              -89.9, min(89.9, centerLat + rand.nextDouble() * degreeRadius));
          var pointLong =
              wrapLongitude(centerLong + rand.nextDouble() * degreeRadius);
          if (distanceBetween(
                  Tuple2(centerLat, centerLong), Tuple2(pointLat, pointLong)) <
              radius / 1000) {
            expect(
                inQuery(
                    queries, geohashForLocation(Tuple2(pointLat, pointLong))),
                equals(true));
          }
        }
      }
    });
  });

  test('String.trim() removes surrounding whitespace', () {
    var string = '  foo ';
    expect(string.trim(), equals('foo'));
  });
}
