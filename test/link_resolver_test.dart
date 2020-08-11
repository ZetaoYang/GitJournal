import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:gitjournal/core/notes_folder_fs.dart';
import 'package:gitjournal/utils/link_resolver.dart';

void main() {
  Directory tempDir;
  NotesFolderFS rootFolder;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('__link_resolver__');

    rootFolder = NotesFolderFS(null, tempDir.path);

    await generateNote(tempDir.path, "Hello.md");
    await generateNote(tempDir.path, "Fire.md");
    await generateNote(tempDir.path, "Folder/Water.md");
    await generateNote(tempDir.path, "Air Bender.md");
    await generateNote(tempDir.path, "zeplin.txt");
    await generateNote(tempDir.path, "Goat  Sim.md");

    await rootFolder.loadRecursively();
  });

  tearDownAll(() async {
    tempDir.deleteSync(recursive: true);
  });

  test('[[Fire]] resolves to base folder `Fire.md`', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[Fire]]');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Fire.md'));
  });

  test('[[Fire.md]] resolves to base folder `Fire.md`', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[Fire.md]]');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Fire.md'));
  });

  test('[[Folder/Water]] resolves to `Folder/Water.md`', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[Folder/Water]]');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Folder/Water.md'));
  });

  test('WikiLinks with spaces resolves correctly', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[Air Bender]]');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Air Bender.md'));
  });

  test('WikiLinks with extra spaces resolves correctly', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[Hello ]]');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Hello.md'));
  });

  test('Resolves to txt files as well', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[zeplin]]');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'zeplin.txt'));
  });

  test('Non base path [[Fire]] should resolve to [[Fire.md]]', () {
    var note = rootFolder.getNoteWithSpec('Folder/Water.md');
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[Fire]]');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Fire.md'));
  });

  test('Non existing wiki link fails', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[Hello2]]');
    expect(resolvedNote, null);
  });

  test('WikiLinks with extra spaces in the middle resolves correctly', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('[[Goat  Sim]]');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Goat  Sim.md'));
  });

  test('Normal relative link', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('./Hello.md');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Hello.md'));
  });

  test('Normal relative link without ./', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('Hello.md');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Hello.md'));
  });

  test('Non existing relative link fails', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('Hello2.md');
    expect(resolvedNote, null);
  });

  test('Complex relative link', () {
    var note = rootFolder.notes[0];
    var linkResolver = LinkResolver(note);

    var resolvedNote = linkResolver.resolve('./Air Bender/../Goat  Sim.md');
    expect(resolvedNote.filePath, p.join(tempDir.path, 'Goat  Sim.md'));
  });
}

Future<void> generateNote(String basePath, String path) async {
  var filePath = p.join(basePath, path);

  // Ensure directory exists
  var dirPath = p.dirname(filePath);
  await Directory(dirPath).create(recursive: true);

  var content = """---
title:
modified: 2017-02-15T22:41:19+01:00
---

Hello""";

  return File(filePath).writeAsString(content, flush: true);
}
