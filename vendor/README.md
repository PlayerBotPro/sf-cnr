# Archived include dependencies

These four includes are committed because their original distributions do not
provide stable sampctl packages. They are source dependencies, separate from
`dependencies/`, which sampctl generates. The files retain their original bytes,
encoding, authorship, and license notices. No standard Pawn or SA-MP includes
are vendored.

| Include | Source and compatibility |
| --- | --- |
| `gvar.inc` | samp-incognito/samp-gvar-plugin [v1.3 release](https://github.com/samp-incognito/samp-gvar-plugin/releases/tag/v1.3), `pawno/include/gvar.inc`; the tagged source repository contains no Pawn header or sampctl resource definition. |
| `regex.inc` | Fro1sha Regular Expression 0.2.1 header from the existing SF-CNR dependency installation; matches the legacy `plugins/regex.dll` (GRGServer/SAMP archive). Preserve its legacy native API; newer regex plugins have different interfaces. |
| `modelsizes.inc` | Y-Less [gist 4543512](https://gist.github.com/Y-Less/4543512), original `modelsizes.inc`; includes its license notice. |
| `sampcac.inc` | [ins1x/sampcac-docs](https://github.com/ins1x/sampcac-docs), `pawno/include/sampcac.inc`, SAMPCAC 0.10.0 for SA-MP 0.3.7. Matches the installed `sampcac_server.dll`. |

The migration copied the already working headers byte for byte; the hashes below
identify the precise snapshots, independently of upstream branch movement.

| Include | SHA-256 |
| --- | --- |
| `gvar.inc` | `480e3852042f242df5295a7131a0a91ac259bc5794d8167de6ccaf52e889e94c` |
| `regex.inc` | `38936b9ecf1ea8da14f045f96fe580b7cf31b3f61ce26c3cfa7fab836c8f7566` |
| `modelsizes.inc` | `458898386785c50878424f7918347996bf7db754d1db7e08287b64f19485ac55` |
| `sampcac.inc` | `f8604ab0ad2c097b7b7c45bbe9f980121bdf44b34ddf0f8c3f15c8257711cefb` |

All other external includes are versioned in `pawn.json` and resolved in
`pawn.lock`. Update each plugin DLL and its include as a matched pair. These
headers supply declarations only; server DLLs and MapAndreas heightmaps are
covered in [RUNNING.md](../RUNNING.md#installed-runtime).

The GVar Apache 2.0 license is also included in
[licenses/gvar-Apache-2.0.md](licenses/gvar-Apache-2.0.md).
