import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:driftfin/models/api_result.dart';

http.Response _base(int statusCode, {String? reasonPhrase}) =>
    http.Response('', statusCode, reasonPhrase: reasonPhrase);

void main() {
  group('ApiError.toString', () {
    test('includes status code and reason when present', () {
      final error = ApiError(statusCode: 404, reason: 'Not Found', message: 'missing');
      expect(error.toString(), '(404) Not Found: missing');
    });

    test('omits status/reason parts when absent', () {
      final error = ApiError(message: 'boom');
      expect(error.toString(), 'boom');
    });

    test('includes only status code when reason is null', () {
      final error = ApiError(statusCode: 500, message: 'boom');
      expect(error.toString(), '(500) boom');
    });
  });

  group('ApiResult', () {
    test('success carries data and isSuccess is true', () {
      final result = ApiResult<String>.success('hi');
      expect(result.isSuccess, isTrue);
      expect(result.data, 'hi');
      expect(result.errorMessage, '');
    });

    test('success can carry null data', () {
      final result = ApiResult<String>.success(null);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('failure carries the error and isSuccess is false', () {
      final result = ApiResult<String>.failure(ApiError(message: 'bad'));
      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
      expect(result.errorMessage, 'bad');
    });
  });

  group('Response<T>.apiResult (sync extension)', () {
    test('successful response with a body of type T returns success', () {
      final response = Response<String>(_base(200), 'hello');
      final result = response.apiResult;
      expect(result.isSuccess, isTrue);
      expect(result.data, 'hello');
    });

    test('successful response whose body is not type T returns success(null)', () {
      final response = Response<String>(_base(204), null);
      final result = response.apiResult;
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('unsuccessful response returns failure with status/reason/body', () {
      final response = Response<String>(_base(404, reasonPhrase: 'Not Found'), null, error: 'nope');
      final result = response.apiResult;
      expect(result.isSuccess, isFalse);
      expect(result.error!.statusCode, 404);
      expect(result.error!.reason, 'Not Found');
      expect(result.error!.message, 'nope');
    });

    test('unsuccessful response falls back to Unknown error when body and error are null', () {
      final response = Response<String>(_base(500), null);
      final result = response.apiResult;
      expect(result.error!.message, 'Unknown error');
    });
  });

  group('Future<Response<T>>.apiResult (async extension)', () {
    test('successful future resolves to success', () async {
      final future = Future.value(Response<int>(_base(200), 42));
      final result = await future.apiResult;
      expect(result.isSuccess, isTrue);
      expect(result.data, 42);
    });

    test('unsuccessful future resolves to failure', () async {
      final future = Future.value(Response<int>(_base(400, reasonPhrase: 'Bad Request'), null, error: 'bad input'));
      final result = await future.apiResult;
      expect(result.isSuccess, isFalse);
      expect(result.error!.statusCode, 400);
      expect(result.error!.reason, 'Bad Request');
      expect(result.error!.message, 'bad input');
    });

    test('a thrown exception is caught and turned into a failure', () async {
      Future<Response<int>> throwing() async => throw Exception('network down');
      final result = await throwing().apiResult;
      expect(result.isSuccess, isFalse);
      expect(result.error!.statusCode, isNull);
      expect(result.errorMessage, contains('network down'));
    });
  });
}
