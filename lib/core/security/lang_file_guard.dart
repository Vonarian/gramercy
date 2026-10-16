import 'package:path/path.dart' as p;

/// Returns true iff [raw] can be safely used as a lang/ file name.
///
/// Community presets are untrusted input: their `file` values are persisted
/// verbatim in the SQLite vault and later joined into filesystem paths during
/// "Reload & Apply" as `p.join(wtPath, 'lang', stored)`.
///
/// Per the `path` package docs, `p.join` does NOT reject or normalize `..`
/// segments, and "if a part is an absolute path, then anything before that
/// will be ignored" — so stored traversal (`../config.blk`) or absolute
/// (`C:\x\v.csv`) values escape `lang/` at open time and combine with the
/// truncating `File.writeAsString` sink to overwrite arbitrary existing files.
/// Windows drive-relative names (`C:victim.csv`) have no root in the windows
/// style (`rootLength` requires a separator after the colon), so
/// `p.basename('C:victim.csv') == 'C:victim.csv'` — only the explicit `:` hold
/// catches them. Likewise, on POSIX a backslash is a plain filename
/// character, so `p.basename(r'..\..\victim.csv') == raw` there; the explicit
/// both-convention separator holds do the real work and `p.basename == raw`
/// is belt-and-braces only. NTFS alternate data streams (`file.csv:stream`)
/// are refused by the same `:` hold.
bool isSafeLangFileName(String raw) {
  if (raw.isEmpty || raw != raw.trim()) return false;
  if (raw == '.' || raw == '..') return false;
  if (raw.contains('/') || raw.contains('\\') || raw.contains(':')) {
    return false;
  }
  // Control characters (incl. CR/LF) never make sense in a preset target and
  // enable log-forging-style surprises downstream.
  if (raw.codeUnits.any((c) => c < 0x20)) return false;
  if (p.basename(raw) != raw) return false;
  return raw.toLowerCase().endsWith('.csv');
}

/// Returns the sandboxed absolute path under `wtPath/lang/` for [raw], or
/// null when [raw] is not safe (use with [isSafeLangFileName] semantics).
String? safeLangFilePath(String wtPath, String raw) {
  if (!isSafeLangFileName(raw)) return null;
  return p.join(wtPath, 'lang', raw);
}
