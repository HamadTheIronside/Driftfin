import 'package:flutter_test/flutter_test.dart';

import 'package:driftfin/models/items/item_shared_models.dart';
import 'package:driftfin/util/string_extensions.dart';

void main() {
  group('capitalize', () {
    test('capitalizes first letter and lowercases the rest', () {
      expect('hELLO'.capitalize(), 'Hello');
      expect('world'.capitalize(), 'World');
    });

    test('empty string returns empty string', () {
      expect(''.capitalize(), '');
    });

    test('single character', () {
      expect('a'.capitalize(), 'A');
    });
  });

  group('rtrim', () {
    test('trims trailing whitespace by default', () {
      expect('hello   '.rtrim(), 'hello');
    });

    test('leaves leading whitespace untouched', () {
      expect('  hello  '.rtrim(), '  hello');
    });

    test('trims custom trailing characters', () {
      expect('hello...'.rtrim(r'.'), 'hello');
    });

    test('no trailing match leaves string unchanged', () {
      expect('hello'.rtrim(), 'hello');
    });
  });

  group('maxLength', () {
    test('truncates and appends ellipsis when longer than limit', () {
      expect('abcdefgh'.maxLength(limitTo: 5), 'abcde...');
    });

    test('returns full substring up to limit when equal length', () {
      expect('abcde'.maxLength(limitTo: 5), 'abcde');
    });

    test('shorter than limit returns whole string', () {
      expect('ab'.maxLength(limitTo: 5), 'ab');
    });

    test('empty string returns empty string', () {
      expect(''.maxLength(limitTo: 5), '');
    });

    test('uses default limit of 75', () {
      final input = 'a' * 100;
      final result = input.maxLength();
      expect(result, '${'a' * 75}...');
    });
  });

  group('getInitials', () {
    test('takes first letter of first two words by default', () {
      expect('John Doe'.getInitials(), 'JD');
    });

    test('respects custom limitTo', () {
      expect('John Middle Doe'.getInitials(limitTo: 3), 'JMD');
    });

    test('empty string returns empty string', () {
      expect(''.getInitials(), '');
    });

    test('single word returns single initial', () {
      expect('John'.getInitials(), 'J');
    });

    test('skips empty segments from repeated spaces', () {
      expect('John  Doe'.getInitials(limitTo: 3), 'JD');
    });

    test('limitTo larger than word count uses all words', () {
      expect('John Doe'.getInitials(limitTo: 5), 'JD');
    });
  });

  group('toUpperCaseSplit', () {
    test('splits camelCase-like uppercase letters with spaces', () {
      expect('HEVC'.toUpperCaseSplit(), 'H E V C');
    });

    test('first character always uppercased without leading space', () {
      expect('abc'.toUpperCaseSplit(), 'Abc');
    });

    test('empty string returns empty string', () {
      expect(''.toUpperCaseSplit(), '');
    });
  });

  group('sanitizedFileName', () {
    test('replaces illegal filesystem characters with underscore', () {
      expect('a<b>c"d?e*f'.sanitizedFileName, 'a_b_c_d_e_f');
    });

    test('trims trailing dots and spaces', () {
      expect('file.name...  '.sanitizedFileName, 'file.name');
    });

    test('empty name falls back to "file"', () {
      expect('   '.sanitizedFileName, 'file');
    });

    test('truncates names longer than 200 characters', () {
      final longName = 'a' * 250;
      expect(longName.sanitizedFileName.length, 200);
    });

    test('takes only the basename portion of a path', () {
      expect('/some/dir/movie.mkv'.sanitizedFileName, 'movie.mkv');
    });
  });

  group('universalBasename', () {
    test('handles unix-style separators', () {
      expect('/some/dir/movie.mkv'.universalBasename, 'movie.mkv');
    });

    test('handles windows-style separators', () {
      expect(r'C:\some\dir\movie.mkv'.universalBasename, 'movie.mkv');
    });

    test('handles mixed separators', () {
      expect(r'/some\dir/movie.mkv'.universalBasename, 'movie.mkv');
    });

    test('no separators returns the string itself', () {
      expect('movie.mkv'.universalBasename, 'movie.mkv');
    });

    test('trailing separator still returns the last non-empty segment', () {
      expect('/some/dir/'.universalBasename, 'dir');
    });

    test('empty string returns empty string', () {
      expect(''.universalBasename, '');
    });
  });

  group('List<String> flatString', () {
    test('joins up to 3 capitalized entries with separator', () {
      expect(['action', 'comedy', 'drama'].flatString(), 'Action | Comedy | Drama');
    });

    test('limits to first 3 entries even if more are provided', () {
      expect(['a', 'b', 'c', 'd'].flatString(), 'A | B | C');
    });

    test('empty list returns empty string', () {
      expect(<String>[].flatString(), '');
    });

    test('single entry returns just that capitalized entry', () {
      expect(['action'].flatString(), 'Action');
    });
  });

  group('GenreItems flatString', () {
    test('joins up to 3 genre names capitalized', () {
      final genres = [
        GenreItems(id: '1', name: 'action'),
        GenreItems(id: '2', name: 'comedy'),
        GenreItems(id: '3', name: 'drama'),
        GenreItems(id: '4', name: 'horror'),
      ];
      expect(genres.flatString(), 'Action | Comedy | Drama');
    });

    test('empty list returns empty string', () {
      expect(<GenreItems>[].flatString(), '');
    });
  });

  group('List<String?> detailsTitle', () {
    test('joins non-null entries with bullet separator', () {
      expect(['2024', 'Action', null].detailsTitle, '2024 ● Action');
    });

    test('all null entries results in empty string', () {
      expect(<String?>[null, null].detailsTitle, '');
    });

    test('empty list results in empty string', () {
      expect(<String?>[].detailsTitle, '');
    });

    test('single non-null entry has no separator', () {
      expect(['2024'].detailsTitle, '2024');
    });
  });
}
