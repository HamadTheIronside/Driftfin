import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/jellyfin/jellyfin_open_api.enums.swagger.dart' as enums;
import 'package:driftfin/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:driftfin/models/account_model.dart';
import 'package:driftfin/models/credentials_model.dart';
import 'package:driftfin/models/login_screen_model.dart';
import 'package:driftfin/providers/auth_provider.dart';
import 'package:driftfin/providers/service_provider.dart';
import 'package:driftfin/providers/user_provider.dart';

/// Exposes a real [Ref] bound to a [ProviderContainer], since several APIs
/// under test (e.g. `ServerQueryResult.fromBaseQuery`, `JellyService`) need a
/// [Ref] rather than the container itself.
final _refProvider = Provider<Ref>((ref) => ref);

Ref _refOf(ProviderContainer container) => container.read(_refProvider);

/// Minimal fake for the `User` notifier so we can drive `userProvider`'s
/// state directly without going through the real notifier's network calls.
class _FakeUser extends User {
  _FakeUser(this.initial);
  final AccountModel? initial;

  @override
  AccountModel? build() => initial;
}

ProviderContainer _containerWith({
  AccountModel? user,
  LoginScreenModel? auth,
}) {
  return ProviderContainer(
    overrides: [
      if (user != null) userProvider.overrideWith(() => _FakeUser(user)),
      if (auth != null) authProvider.overrideWith((ref) => AuthNotifier(ref)..state = auth),
    ],
  );
}

AccountModel _accountWithUrl(String url) {
  return AccountModel(
    name: 'test',
    id: 'user-id',
    avatar: '',
    lastUsed: DateTime(2024),
    credentials: CredentialsModel.internal(url: url),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServerQueryResult.fromBaseQuery', () {
    test('maps items, totalRecordCount and startIndex from the base query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dto1 = const BaseItemDto(id: 'a', name: 'Alpha');
      final dto2 = const BaseItemDto(id: 'b', name: 'Beta');
      final baseQuery = BaseItemDtoQueryResult(
        items: [dto1, dto2],
        totalRecordCount: 42,
        startIndex: 5,
      );

      final result = ServerQueryResult.fromBaseQuery(baseQuery, _refOf(container));

      expect(result.original, [dto1, dto2]);
      expect(result.items, hasLength(2));
      expect(result.items.map((e) => e.id), ['a', 'b']);
      expect(result.totalRecordCount, 42);
      expect(result.startIndex, 5);
    });

    test('defaults to empty items list when items is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const baseQuery = BaseItemDtoQueryResult(items: null, totalRecordCount: null, startIndex: null);
      final result = ServerQueryResult.fromBaseQuery(baseQuery, _refOf(container));

      expect(result.original, isEmpty);
      expect(result.items, isEmpty);
      expect(result.totalRecordCount, isNull);
      expect(result.startIndex, isNull);
    });
  });

  group('ServerQueryResult.copyWith', () {
    test('overrides only the provided fields', () {
      final original = ServerQueryResult(
        original: const [],
        items: const [],
        totalRecordCount: 1,
        startIndex: 0,
      );

      final copy = original.copyWith(totalRecordCount: 99);

      expect(copy.totalRecordCount, 99);
      expect(copy.startIndex, 0);
      expect(copy.original, original.original);
      expect(copy.items, original.items);
    });

    test('with no arguments returns equivalent values', () {
      final dto = const BaseItemDto(id: 'x');
      final original = ServerQueryResult(
        original: [dto],
        items: const [],
        totalRecordCount: 3,
        startIndex: 1,
      );

      final copy = original.copyWith();

      expect(copy.original, original.original);
      expect(copy.items, original.items);
      expect(copy.totalRecordCount, 3);
      expect(copy.startIndex, 1);
    });
  });

  group('ParsedMap.parseValues', () {
    test('parses int-like strings to int', () {
      final result = {'a': '42'}.parseValues();
      expect(result['a'], 42);
      expect(result['a'], isA<int>());
    });

    test('parses double-like strings to double', () {
      final result = {'a': '3.14'}.parseValues();
      expect(result['a'], 3.14);
      expect(result['a'], isA<double>());
    });

    test('parses "true"/"false" case-insensitively to bool', () {
      final result = {
        'a': 'true',
        'b': 'FALSE',
        'c': 'True',
        'd': 'false',
      }.parseValues();
      expect(result['a'], isTrue);
      expect(result['b'], isFalse);
      expect(result['c'], isTrue);
      expect(result['d'], isFalse);
    });

    test('leaves plain non-numeric, non-boolean strings untouched', () {
      final result = {'a': 'hello world'}.parseValues();
      expect(result['a'], 'hello world');
    });

    test('passes through non-string values unchanged', () {
      final result = {
        'a': 1,
        'b': true,
        'c': null,
        'd': [1, 2, 3],
      }.parseValues();
      expect(result['a'], 1);
      expect(result['b'], true);
      expect(result['c'], isNull);
      expect(result['d'], [1, 2, 3]);
    });

    test('empty map returns empty map', () {
      expect(<String, dynamic>{}.parseValues(), isEmpty);
    });

    test('mixed map parses each entry independently', () {
      final result = {
        'count': '10',
        'ratio': '0.5',
        'enabled': 'TRUE',
        'name': 'driftfin',
        'raw': 7,
      }.parseValues();
      expect(result['count'], 10);
      expect(result['ratio'], 0.5);
      expect(result['enabled'], true);
      expect(result['name'], 'driftfin');
      expect(result['raw'], 7);
    });
  });

  group('JellyService.buildVideoStreamUrl', () {
    test('with no optional params set, returns just base path (no query string)', () {
      final container = _containerWith(user: _accountWithUrl('http://server.local:8096'));
      addTearDown(container.dispose);
      final service = JellyService(_refOf(container), fakeJellyfinOpenApiStub());

      final url = service.buildVideoStreamUrl(itemId: 'item1', container: 'mp4');

      expect(url, 'http://server.local:8096/Videos/item1/stream.mp4');
    });

    test('trims a trailing slash from the server URL', () {
      final container = _containerWith(user: _accountWithUrl('http://server.local:8096/'));
      addTearDown(container.dispose);
      final service = JellyService(_refOf(container), fakeJellyfinOpenApiStub());

      final url = service.buildVideoStreamUrl(itemId: 'item1', container: 'mp4');

      expect(url, 'http://server.local:8096/Videos/item1/stream.mp4');
    });

    test('builds a query string with several params set, correctly encoded', () {
      final container = _containerWith(user: _accountWithUrl('http://server.local'));
      addTearDown(container.dispose);
      final service = JellyService(_refOf(container), fakeJellyfinOpenApiStub());

      final url = service.buildVideoStreamUrl(
        itemId: 'item1',
        container: 'mp4',
        $static: true,
        tag: 'tag value/with slash',
        maxHeight: 1080,
        audioCodec: 'aac',
        framerate: 23.976,
      );

      expect(url, startsWith('http://server.local/Videos/item1/stream.mp4?'));
      final query = Uri.parse(url).queryParameters;
      expect(query['static'], 'true');
      expect(query['tag'], 'tag value/with slash');
      expect(query['maxHeight'], '1080');
      expect(query['audioCodec'], 'aac');
      expect(query['framerate'], '23.976');
    });

    test('URL-encodes special characters in query values', () {
      final container = _containerWith(user: _accountWithUrl('http://server.local'));
      addTearDown(container.dispose);
      final service = JellyService(_refOf(container), fakeJellyfinOpenApiStub());

      final url = service.buildVideoStreamUrl(
        itemId: 'item1',
        container: 'mp4',
        deviceId: 'device id&with=chars',
      );

      expect(url, contains(Uri.encodeComponent('device id&with=chars')));
      expect(url, isNot(contains('device id&with=chars')));
    });

    test('serializes enum params using their .value', () {
      final container = _containerWith(user: _accountWithUrl('http://server.local'));
      addTearDown(container.dispose);
      final service = JellyService(_refOf(container), fakeJellyfinOpenApiStub());

      final url = service.buildVideoStreamUrl(
        itemId: 'item1',
        container: 'mp4',
        subtitleMethod: enums.VideosItemIdStreamContainerGetSubtitleMethod.embed,
        context: enums.VideosItemIdStreamContainerGetContext.streaming,
      );

      final query = Uri.parse(url).queryParameters;
      expect(query['subtitleMethod'], 'Embed');
      expect(query['context'], 'Streaming');
    });

    test('prefers the temp auth server URL over the current user URL', () {
      final container = _containerWith(
        user: _accountWithUrl('http://user-server.local'),
        auth: LoginScreenModel(
          serverLoginModel: ServerLoginModel(
            tempCredentials: CredentialsModel.internal(url: 'http://temp-server.local'),
          ),
        ),
      );
      addTearDown(container.dispose);
      final service = JellyService(_refOf(container), fakeJellyfinOpenApiStub());

      final url = service.buildVideoStreamUrl(itemId: 'item1', container: 'mp4');

      expect(url, startsWith('http://temp-server.local'));
    });

    test('falls back to empty base URL when neither provider has a URL', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = JellyService(_refOf(container), fakeJellyfinOpenApiStub());

      final url = service.buildVideoStreamUrl(itemId: 'item1', container: 'mp4');

      expect(url, '/Videos/item1/stream.mp4');
    });

    test('falsy/zero numeric params are still included (only null is excluded)', () {
      final container = _containerWith(user: _accountWithUrl('http://server.local'));
      addTearDown(container.dispose);
      final service = JellyService(_refOf(container), fakeJellyfinOpenApiStub());

      final url = service.buildVideoStreamUrl(
        itemId: 'item1',
        container: 'mp4',
        startTimeTicks: 0,
        audioStreamIndex: 0,
      );

      final query = Uri.parse(url).queryParameters;
      expect(query['startTimeTicks'], '0');
      expect(query['audioStreamIndex'], '0');
    });
  });
}

/// `buildVideoStreamUrl` is a pure function that never touches `api`, so any
/// [JellyfinOpenApi] instance works here; `.create()` just wires up a chopper
/// client without performing any network I/O.
JellyfinOpenApi fakeJellyfinOpenApiStub() => JellyfinOpenApi.create();
