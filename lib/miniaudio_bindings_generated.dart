// Generated bindings for miniaudio.
// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_single_quotes
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: unnecessary_import

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

class MiniaudioBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
  _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  MiniaudioBindings(ffi.DynamicLibrary dynamicLibrary)
    : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  MiniaudioBindings.fromLookup(
    ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  /// Initialize the miniaudio engine
  int miniaudio_init() {
    return _miniaudio_init();
  }

  late final _miniaudio_initPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('miniaudio_init');
  late final _miniaudio_init = _miniaudio_initPtr.asFunction<int Function()>();

  /// Play an audio file
  int miniaudio_play_sound(ffi.Pointer<ffi.Char> file_path) {
    return _miniaudio_play_sound(file_path);
  }

  late final _miniaudio_play_soundPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<ffi.Char>)>>(
        'miniaudio_play_sound',
      );
  late final _miniaudio_play_sound = _miniaudio_play_soundPtr
      .asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  /// Load a sound into memory
  int miniaudio_load_sound(ffi.Pointer<ffi.Char> file_path) {
    return _miniaudio_load_sound(file_path);
  }

  late final _miniaudio_load_soundPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<ffi.Char>)>>(
        'miniaudio_load_sound',
      );
  late final _miniaudio_load_sound = _miniaudio_load_soundPtr
      .asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  /// Play a previously loaded sound
  int miniaudio_play_loaded_sound() {
    return _miniaudio_play_loaded_sound();
  }

  late final _miniaudio_play_loaded_soundPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('miniaudio_play_loaded_sound');
  late final _miniaudio_play_loaded_sound = _miniaudio_play_loaded_soundPtr
      .asFunction<int Function()>();

  /// Stop all sounds
  void miniaudio_stop_all_sounds() {
    return _miniaudio_stop_all_sounds();
  }

  late final _miniaudio_stop_all_soundsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>(
        'miniaudio_stop_all_sounds',
      );
  late final _miniaudio_stop_all_sounds = _miniaudio_stop_all_soundsPtr
      .asFunction<void Function()>();

  /// Check if engine is initialized
  int miniaudio_is_initialized() {
    return _miniaudio_is_initialized();
  }

  late final _miniaudio_is_initializedPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>(
        'miniaudio_is_initialized',
      );
  late final _miniaudio_is_initialized = _miniaudio_is_initializedPtr
      .asFunction<int Function()>();

  /// Cleanup the miniaudio engine
  void miniaudio_cleanup() {
    return _miniaudio_cleanup();
  }

  late final _miniaudio_cleanupPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('miniaudio_cleanup');
  late final _miniaudio_cleanup = _miniaudio_cleanupPtr
      .asFunction<void Function()>();
}
